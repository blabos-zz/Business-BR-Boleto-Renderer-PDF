requires 'Business::BR::Boleto::Utils' => '0.000001';
requires 'Const::Fast'                 => '0.014';
requires 'Cwd'                         => '3.47';
requires 'Digest::SHA'                 => '5.92';
requires 'Encode'                      => '2.62';
requires 'File::Path'                  => '2.09';
requires 'File::ShareDir'              => '1.102';
requires 'File::Spec::Functions'       => '3.47';
requires 'Locale::Currency::Format'    => '1.30';
requires 'Moo'                         => '1.00600';
requires 'PDF::API2'                   => '2.023';

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker' => '6.30';
};

on 'develop' => sub {
    requires 'Pod::Coverage::TrustPod' => '0';
    requires 'Test::Pod'               => '1.41';
    requires 'Test::Pod::Coverage'     => '1.08';
};
