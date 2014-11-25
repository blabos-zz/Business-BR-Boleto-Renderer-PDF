#!perl

use Data::Dumper;
use DDP;

use Business::BR::Boleto;
use Business::BR::Boleto::Renderer::PDF;

my $b = Business::BR::Boleto->new(
    banco   => 'Itau',
    cedente => {
        nome      => 'Nome do cedente',
        endereco  => 'Endereço do cedente',
        documento => '12.345.678/0001-23',
        agencia   => { numero => '1234' },
        conta     => { numero => '56789', dv => '0' },
        carteira  => '175',
    },
    sacado => {
        nome      => 'Nome do sacado',
        endereco  => 'Endereço do sacado',
        documento => '09876543210',
    },
    pagamento => {
        valor_documento  => 10.00,
        nosso_numero     => 3,
        numero_documento => 3,
        instrucoes       => '',
    }
);
$r = Business::BR::Boleto::Renderer::PDF->new( base_dir => q{/tmp} );
$r->render($b);
