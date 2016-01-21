# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package EthercalcRevisionTool;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(slurp);
use Mojo::JSON qw(true false);
use Mojo::URL;
use File::Spec;
use File::Basename;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $config = $self->plugin('Config' => {
        default =>  {
            theme         => 'default',
        }
    });

    die ('You need to set rev_dir in the configuration file!') unless (defined($self->config('rev_dir')));
    die ('You need to set ethercalc_url in the configuration file!') unless (defined($self->config('ethercalc_url')));

    # Themes handling
    shift @{$self->renderer->paths};
    shift @{$self->static->paths};
    if ($config->{theme} ne 'default') {
        my $theme = $self->home->rel_dir('themes/'.$config->{theme});
        push @{$self->renderer->paths}, $theme.'/templates' if -d $theme.'/templates';
        push @{$self->static->paths}, $theme.'/public' if -d $theme.'/public';
    }
    push @{$self->renderer->paths}, $self->home->rel_dir('themes/default/templates');
    push @{$self->static->paths}, $self->home->rel_dir('themes/default/public');

    # Internationalization
    my $lib = $self->home->rel_dir('themes/'.$config->{theme}.'/lib');
    eval qq(use lib "$lib");
    $self->plugin('I18N');

    # Debug
    $self->plugin('DebugDumperHelper');

    $self->secrets($self->config('secrets'));

    # Check rev_dir permissions
    die ('The upload directory ('.$self->config('rev_dir').') is not readable or I can\'t go in!') unless (-r $self->config('rev_dir') && -x $self->config('rev_dir'));

    # Default layout
    $self->defaults(layout => 'default');

    # Router
    my $r = $self->routes;

    # Displaying revisions
    $r->get('/:calc' => sub {
        my $c    = shift;
        my $calc = $c->param('calc');
        my $dir  = File::Spec->catdir(($c->config('rev_dir'), $calc));

        my ($msg, @revs);

        if (-e $dir) {
            my @t = glob($dir.'/*txt');
            $msg  = $c->l('Unable to find any revision for the calc %1.', $calc) unless (scalar(@t));

            for my $rev (@t) {
                $rev = basename $rev;
                $rev =~ s/\.txt//;
                push @revs, $rev;
            }
            @revs = sort { $b <=> $a } @revs;
        } else {
            $msg = $c->l('Unable to find any revision for the calc %1.', $calc);
        }

        return $c->render(
            template => 'index',
            msg      => $msg,
            revs     => \@revs
        );
    })->name('index');

    # Get the raw revision file
    $r->get('/rev/:calc/:revision' => sub {
        my $c       = shift;
        my $calc    = $c->param('calc');
        my $rev     = $c->param('revision');

        my $file    = File::Spec->catfile(($c->config('rev_dir'), $calc, $rev.'.txt'));

        my $msg     = $c->l('The revision %1 of the calc %2 doesn\'t seems to exist.', $rev, $calc) unless (-e $file);
        $msg        = $c->l('Unable to read the revision %1 of the calc %2.', $rev, $calc) unless (-r $file);

        if (defined($msg)) {
            return $c->render(
                json => {
                    success => false,
                    msg     => $msg,
                }
            );
        } else {
            $c->res->headers->content_type('text/x-socialcalc');
            $c->reply->asset(Mojo::Asset::File->new(path => $file));
        }
    })->name('rev');

    # Check if a revision exists for a calc
    $r->get('/rev_exists/:calc' => sub {
        my $c    = shift;
        my $calc = $c->param('calc');

        my $dir  = File::Spec->catdir(($c->config('rev_dir'), $calc));
        my @t    = glob($dir.'/*txt');

        my $exists = (scalar @t) ? true : false;

        return $c->render(
            json => {
                exists => $exists
            }
        );
    })->name('exists');

    # Reload a revision
    $r->post('/' => sub {
        my $c    = shift;
        my $calc = $c->param('calc');
        my $rev  = $c->param('revision');

        my $file    = File::Spec->catfile(($c->config('rev_dir'), $calc, $rev.'.txt'));

        my $success = false;
        my $msg     = $c->l('The revision %1 of the calc %2 doesn\'t seems to exist.', $rev, $calc) unless (-e $file);
        $msg        = $c->l('Unable to read the revision %1 of the calc %2.', $rev, $calc) unless (-r $file);

        unless (defined($msg)) {
            my $content = slurp($file) unless (defined($msg));

            my $comp    = (substr($self->config('ethercalc_url'), -1, 1) eq '/') ? '_/' : '/_/';

            my $url     = Mojo::URL->new($c->req->url->to_abs->to_string);
            $c->debug($url->to_abs);
            $url->path($self->config('ethercalc_url').$comp.$calc);
            $url->scheme($c->req->headers->header('X-Forwarded-Proto'));
            $c->debug($url->to_abs->to_string);

            my $tx = $c->ua->put($url => $content);
            if ($tx->success) {
                $success = true;
            } else {
                my $error = (defined $tx->error->{code}) ? $c->l('Code: %1<br>%2', $tx->error->{code}, $tx->error->{message}) : $tx->error->{message};
                $msg = $c->l('Something went wrong when trying to restore %1 on calc %2:<br>%3', $rev, $calc, $error);
            }
        }

        return $c->render(
            json => {
                success => $success,
                msg     => $msg
            }
        );
    })->name('backintime');

}

1;
