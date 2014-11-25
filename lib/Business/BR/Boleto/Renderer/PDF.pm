package Business::BR::Boleto::Renderer::PDF;

use Moo;
with 'Business::BR::Boleto::Role::Renderer';

use PDF::API2;
use Const::Fast;
use Locale::Currency::Format;

use Business::BR::Boleto::Utils qw{ mod11 };

use Cwd qw{ abs_path };
use Digest::SHA qw{ sha1_hex };
use Encode qw{ decode_utf8 };
use File::Path qw{ make_path };
use File::ShareDir qw{ module_file };
use File::Spec::Functions qw{ catdir };

has 'base_dir' => (
    is       => 'ro',
    required => 1,
);

has 'template' => (
    is      => 'ro',
    builder => sub {
        module_file( 'Business::BR::Boleto::Renderer::PDF', 'template.pdf' );
    },
);

sub render {
    my ( $self, $boleto ) = @_;

    my $pdf  = PDF::API2->open( $self->template );
    my $font = $pdf->corefont('Helvetica');
    my $page = $pdf->openpage(1);
    my $text = $page->text;

    ## Data do documento / data de processamento
    my $data_documento =
      $boleto->pagamento->data_documento->strftime('%d/%m/%Y');

    ## Data de vencimento
    my $data_vencimento =
      $boleto->pagamento->data_vencimento->strftime('%d/%m/%Y');

    ## Valor do documento
    my $valor_documento =
      currency_format( 'BRL', $boleto->pagamento->valor_documento, FMT_COMMON );

    ##########################################################################
    ## Corpo - Ficha de Compensação
    ##########################################################################
    $text->font( $font, 8 );

    _print( $text, 19,  421, $boleto->pagamento->local_pagamento );
    _print( $text, 19,  398, $boleto->cedente->nome );
    _print( $text, 19,  375, $data_documento );
    _print( $text, 334, 375, $data_documento );
    _print( $text, 93,  375, $boleto->pagamento->numero_documento );
    _print( $text, 183, 375, $boleto->pagamento->especie );
    _print( $text, 271, 375, $boleto->pagamento->aceite );
    _print( $text, 93,  353, $boleto->cedente->carteira );
    _print( $text, 150, 353, $boleto->pagamento->moeda );
    _print( $text, 228, 353, $boleto->pagamento->quantidade );
    _print( $text, 334, 353, $boleto->pagamento->valor );
    _print( $text, 455, 421, $data_vencimento );
    _print( $text, 455, 398, $boleto->banco->codigo_cedente );
    _print( $text, 455, 375, $boleto->banco->nosso_numero );
    _print( $text, 455, 353, $valor_documento );
    _print( $text, 19,  217, $boleto->sacado->nome );
    _print( $text, 19,  205, $boleto->sacado->documento );
    _print( $text, 19,  193, $boleto->sacado->endereco );
    _print( $text, 19,  168, $boleto->avalista->nome );
    _print( $text, 19,  156, $boleto->avalista->documento );
    _print( $text, 19,  144, $boleto->avalista->endereco );

    ## Instruções
    my @instrucoes =
      ref $boleto->pagamento->instrucoes eq 'ARRAY'
      ? @{ $boleto->pagamento->instrucoes }
      : split /\n/,
      $boleto->pagamento->instrucoes;

    foreach my $linha ( 0 .. @instrucoes ) {
        _print( $text, 19, 324 - 12 * $linha, $instrucoes[$linha] );
    }

    ##########################################################################
    ## Corpo - Recibo do Sacado
    ##########################################################################

    _print( $text, 19,  641, $boleto->cedente->nome );
    _print( $text, 397, 641, $boleto->pagamento->especie );
    _print( $text, 432, 641, $boleto->pagamento->quantidade );
    _print( $text, 478, 641, $boleto->pagamento->nosso_numero );
    _print( $text, 19,  618, $boleto->pagamento->numero_documento );
    _print( $text, 195, 618, $boleto->cedente->documento );
    _print( $text, 313, 618, $data_vencimento );
    _print( $text, 432, 618, $valor_documento );
    _print( $text, 19,  572, $boleto->sacado->nome );
    _print( $text, 460, 572, $boleto->sacado->documento );

    ##########################################################################
    ## Código de barras
    ##########################################################################
    my $barcode = $pdf->xo_2of5int(
        '-code' => $boleto->febraban->codigo_barras,
        '-zone' => 40,
    );

    $page->gfx->formimage( $barcode, 19, 90 );

    ##########################################################################
    ## Cabeçalho
    ##########################################################################
    $font = $pdf->corefont('Helvetica-Bold');
    $text->font( $font, 13 );
    _print( $text, 214, 670, $boleto->febraban->linha_digitavel );
    _print( $text, 214, 450, $boleto->febraban->linha_digitavel );

    $text->font( $font, 18 );
    my $cod_banco = $boleto->banco->codigo;
    my $dv_banco  = mod11($cod_banco);
    _print( $text, 155, 668, $cod_banco . '-' . $dv_banco );
    _print( $text, 155, 448, $cod_banco . '-' . $dv_banco );

    my $logo = $boleto->banco->logo;
    my $png  = $pdf->image_png($logo);
    $page->gfx->image( $png, 13.05, 658.25, 133.60, 34.10 );
    $page->gfx->image( $png, 13.05, 439.30, 133.60, 34.10 );

    $pdf->saveas( $self->_file( $boleto->febraban->codigo_barras ) );
}

sub _file {
    my ( $self, $codigo_barras ) = @_;

    my $hash = sha1_hex $codigo_barras;
    my $dir  = $self->base_dir;
    my $path = catdir( $dir, map { substr $hash, 0, $_ } 1 .. 3 );

    make_path($path);

    return abs_path( catdir( $path, $hash . '.pdf' ) );
}

sub _print {
    my ( $element, $x, $y, $content ) = @_;

    $element->translate( $x, $y );
    $element->text( decode_utf8 $content);
}

1;

#ABSTRACT: Renderizador de boletos em PDF

