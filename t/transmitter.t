#!/usr/bin/perl

use strict;
use warnings;
use lib 't';

use FusionInventory::Agent::Transmitter;
use FusionInventory::Agent::XML::Query::SimpleMessage;
use FusionInventory::Logger;
use FusionInventory::Test::Server;
use FusionInventory::Test::Proxy;
use Test::More;
use Test::Exception;
use Compress::Zlib;
use Socket;

plan tests => 41;

my $ok = sub {
    my ($server, $cgi) = @_;

    print "HTTP/1.0 200 OK\r\n";
    print "\r\n";
    print compress("hello");
};

my $logger = FusionInventory::Logger->new({
    backends => [ 'Test' ]
});

my $message = FusionInventory::Agent::XML::Query::SimpleMessage->new({
    deviceid => 'foo',
    msg => {
        foo => 'foo',
        bar => 'bar'
    },
});

my ($transmitter, $server, $response);

# instanciations tests

throws_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        ca_cert_file => '/no/such/file',
        logger       => $logger
    });
} qr/^non-existing certificate file/,
'instanciation: invalid ca cert file';

throws_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        ca_cert_dir => '/no/such/directory',
        logger       => $logger
    });
} qr/^non-existing certificate directory/,
'instanciation: invalid ca cert directory';

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger => $logger
    });
} 'instanciation: http';

# compression tests

my $data = "this is a test";
is(
    $transmitter->_uncompressNative($transmitter->_compressNative($data)),
    $data,
    'round-trip compression with Compress::Zlib'
);

is(
    $transmitter->_uncompressGzip($transmitter->_compressGzip($data)),
    $data,
    'round-trip compression with Gzip'
);

# no connection tests
BAIL_OUT("port aleady used") if test_port(8080);

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'http://localhost:8080/public',
        }),
        $logger,
        qr/^Can't connect to localhost:8080/
    );
};

# http connection tests

$server = FusionInventory::Test::Server->new(
    port     => 8080,
    user     => 'test',
    realm    => 'test',
    password => 'test',
);
$server->set_dispatch({
    '/public'  => $ok,
    '/private' => sub { return $ok->(@_) if $server->authenticate(); }
});
$server->background() or BAIL_OUT("can't launch the server");

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'http://localhost:8080/public',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger => $logger
    });
} 'instanciation: http, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
                message => $message,
                url     => 'http://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    );
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user     => 'test',
        password => 'test',
        logger   => $logger,
    });
} 'instanciation:  http, auth, with credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'http://localhost:8080/private',
    }));
};

$server->stop();

# https connection tests

$server = FusionInventory::Test::Server->new(
    port     => 8080,
    user     => 'test',
    realm    => 'test',
    password => 'test',
    ssl      => 1,
    crt      => 't/ssl/crt/good.pem',
    key      => 't/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
    '/private' => sub { return $ok->(@_) if $server->authenticate(); }
});
$server->background();

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        no_ssl_check => 1,
    });
} 'instanciation: https, check disabled';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/public',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        no_ssl_check => 1,
    });
} 'instanciation: https, check disabled, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'https://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    );
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user         => 'test',
        password     => 'test',
        logger       => $logger,
        no_ssl_check => 1,
    });
} 'instanciation: https, check disabled, auth, credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/private',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
    });
} 'instanciation: https';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/public',
    })); 
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
    });
} 'instanciation: https, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'https://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    );
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user         => 'test',
        password     => 'test',
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
    });
} 'instanciation: https, auth, credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/private',
    }));
};

$server->stop();

# http connection through proxy tests

$server = FusionInventory::Test::Server->new(
    port     => 8080,
    user     => 'test',
    realm    => 'test',
    password => 'test',
);
$server->set_dispatch({
    '/public'  => sub {
        return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR};
    },
    '/private' => sub {
        return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR} &&
                            $server->authenticate();
    }
});
$server->background();

my $proxy = FusionInventory::Test::Proxy->new();
$proxy->background();

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger => $logger,
        proxy  => $proxy->url()
    });
} 'instanciation: http, proxy';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'http://localhost:8080/public',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger => $logger,
        proxy  => $proxy->url()
    });
} 'instanciation: http, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'http://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    ); 
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user     => 'test',
        password => 'test',
        logger   => $logger,
        proxy    => $proxy->url()
    });
} 'instanciation: http, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'http://localhost:8080/private',
    }));
};

$server->stop();

# https connection through proxy tests

$server = FusionInventory::Test::Server->new(
    port     => 8080,
    user     => 'test',
    realm    => 'test',
    password => 'test',
    ssl      => 1,
    crt      => 't/ssl/crt/good.pem',
    key      => 't/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => sub { return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR}; },
    '/private' => sub { return $ok->(@_) if $ENV{HTTP_X_FORWARDED_FOR} && $server->authenticate(); }
});
$server->background();

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        no_ssl_check => 1,
        proxy        => $proxy->url()
    });
} 'instanciation: https, proxy, check disabled';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/public',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        no_ssl_check => 1,
        proxy        => $proxy->url()
    });
} 'instanciation: https, check disabled, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'https://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    );
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user         => 'test',
        password     => 'test',
        logger       => $logger,
        no_ssl_check => 1,
        proxy        => $proxy->url()
    });
} 'instanciation: https, check disabled, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/private',
    }));
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
        proxy        => $proxy->url()
    });
} 'instanciation: https';

subtest "correct response" => sub {
    check_response_ok($response = $transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/public',
    })); 
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
        proxy        => $proxy->url()
    });
} 'instanciation: https, proxy, auth, no credentials';

subtest "no response" => sub {
    check_response_nok(
        scalar $transmitter->send({
            message => $message,
            url     => 'https://localhost:8080/private',
        }),
        $logger,
        "Authentication required, no credentials available",
    ); 
};

lives_ok {
    $transmitter = FusionInventory::Agent::Transmitter->new({
        user         => 'test',
        password     => 'test',
        logger       => $logger,
        ca_cert_file => 't/ssl/crt/ca.pem',
        proxy        => $proxy->url()
    });
} 'instanciation: https, proxy, auth, credentials';

subtest "correct response" => sub {
    check_response_ok($transmitter->send({
        message => $message,
        url     => 'https://localhost:8080/private',
    }));
};

$server->stop();
$proxy->stop();


sub check_response_ok {
    my ($response) = @_;

    plan tests => 3;
    ok(defined $response, "response from server");
    isa_ok(
        $response,
        'FusionInventory::Agent::XML::Response',
        'response class'
    );
    is($response->getContent(), 'hello', 'response content');
}

sub check_response_nok {
    my ($response, $logger, $message) = @_;

    plan tests => 3;
    ok(!defined $response,  "no response");
    is(
        $logger->{backends}->[0]->{level},
        'error',
        "error message level"
    );
    if (ref $message eq 'Regexp') {
        like(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    } else {
        is(
            $logger->{backends}->[0]->{message},
            $message,
            "error message content"
        );
    }
}

sub test_port {
    my $port   = $_[0];

    my $iaddr = inet_aton('localhost');
    my $paddr = sockaddr_in($port, $iaddr);
    my $proto = getprotobyname('tcp');
    if (socket(my $socket, PF_INET, SOCK_STREAM, $proto)) {
        if (connect($socket, $paddr)) {
            close $socket;
            return 1;
        } 
    }

    return 0;
}
