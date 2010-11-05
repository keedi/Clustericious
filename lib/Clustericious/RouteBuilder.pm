package Clustericious::RouteBuilder;
use strict;
use warnings;

our %Routes;

# Much of the code below taken directly from Mojolicious::Lite.
sub import {
    my $class = shift;
    my $caller = caller;
    my $app_class;
    if (@_) { # allow specification in the "use".
        $app_class = shift;
    } elsif ($caller->isa("Clustericious::App")) {
        $app_class = $caller;
    } else {
        $app_class = $caller;
        $app_class =~ s/::Routes$// or die "could not guess app class : ";
    }
    my @routes;
    $Routes{$app_class} = \@routes;

    # Route generator
    my $route_sub = sub {
        my ($methods, @args) = @_;

        my ($cb, $constraints, $defaults, $name, $pattern);
        my $conditions = [];

        # Route information
        my $condition;
        while (my $arg = shift @args) {

            # Condition can be everything
            if ($condition) {
                push @$conditions, $condition => $arg;
                $condition = undef;
            }

            # First scalar is the pattern
            elsif (!ref $arg && !$pattern) { $pattern = $arg }

            # Scalar
            elsif (!ref $arg && @args) { $condition = $arg }

            # Last scalar is the route name
            elsif (!ref $arg) { $name = $arg }

            # Callback
            elsif (ref $arg eq 'CODE') { $cb = $arg }

            # Constraints
            elsif (ref $arg eq 'ARRAY') { $constraints = $arg }

            # Defaults
            elsif (ref $arg eq 'HASH') { $defaults = $arg }
        }

        # Defaults
        $cb ||= sub {1};
        $constraints ||= [];

        # Merge
        $defaults ||= {};
        $defaults = {%$defaults, cb => $cb};

        # Name
        $name ||= '';

        push @routes, {
            name        => $name,
            pattern     => $pattern,
            constraints => $constraints,
            conditions  => $conditions,
            defaults    => $defaults,
            methods     => $methods
          };

    };

    # Prepare exports
    no strict 'refs';
    no warnings 'redefine';

    # Export
    *{"${caller}::any"}          = sub { $route_sub->(ref $_[0] ? shift : [], @_) };
    *{"${caller}::get"}          = sub { $route_sub->('get', @_) };
    *{"${caller}::ladder"}       = sub { $route_sub->('ladder', @_) };
    *{"${caller}::post"}         = sub { $route_sub->('post', @_) };
    *{"${caller}::Delete"}       = sub { $route_sub->('delete', @_) };
    *{"${caller}::websocket"}    = sub { $route_sub->('websocket', @_) };
    *{"${caller}::authenticate"} = sub { $route_sub->('authenticate',@_) };
    *{"${caller}::authorize"}    = sub { $route_sub->('authorize',@_) };
}

sub add_routes {
    my $class = shift;
    my $app = shift;

    my $stashed = $Routes{ ref $app }
      or Carp::confess("no routes stashed for $app");
    my @stashed            = @$stashed;
    my $routes             = $app->routes;
    my $head_route         = $app->routes;
    my $head_authenticated = $head_route;

    for my $spec (@stashed) {
       my      ($name,$pattern,$constraints,$conditions,$defaults,$methods) =
       @$spec{qw/name  pattern  constraints  conditions  defaults  methods/};

         # authenticate, always connects to app->routes
         if (!ref $methods && $methods eq 'authenticate') {
             my $realm = $pattern || ref $app;
             $head_route = $head_authenticated = $routes =
             $app->routes->bridge->to( {
                    cb => sub {
                        my $c = shift;
                        return 1 unless $c->config->simple_auth(default => '');
                        $c->app->plugins->load_plugin('simple_auth')
                            ->authenticate( $c, $realm );
                      }
                });
             next;
         }

         # authorize replaces previous authorize's
         if (!ref $methods && $methods eq 'authorize') {
            die "put authenticate before authorize" unless $head_authenticated;
            my $action = $pattern;
            my $resource = $name;
            $head_route = $routes = $head_authenticated->bridge->to( {
                    cb => sub {
                        my $c = shift;
                        return 1 unless $c->config->simple_auth(default => '');
                        $c->app->plugins->load_plugin('simple_auth')
                            ->authorize( $c, $action, $resource || $c->req->url->path );
                      } });
            next;
         }

         # ladders replace previous ladders
         if (!ref $methods && $methods eq 'ladder') {
              $routes = $head_route->bridge( $pattern, {@$constraints} )->over($conditions)
                  ->to($defaults)->name($name);
              next;
         }

         # WebSocket?
         my $websocket = 1 if !ref $methods && $methods eq 'websocket';
         $methods = [] if $websocket;

         # Create route
         my $route =
           $routes->route( $pattern, {@$constraints} )->over($conditions)
           ->via($methods)->to($defaults)->name($name);

         # WebSocket
         $route->websocket if $websocket;
     }
}

1;

