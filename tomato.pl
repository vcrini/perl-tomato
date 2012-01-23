#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  layout.pl
#
#        USAGE:  ./layout.pl
#
#  DESCRIPTION:  Pomodoro Implementation
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Valerio Crini (vcrini), vcrini@gmail.com
#      COMPANY:  Netos
#      VERSION:  0.2.2
#      CREATED:  14/11/2010 09:53:24
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use DateTime::Duration;
use DateTime::Format::Duration;
use Gtk2 -init;
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect( delete_event => sub { Gtk2->main_quit } );

my $default = 25 * 60;

#my $default = 5;

my $default2 = 5 * 60;

#my $default2 = 2;
my %counters = (
    clock  => 0,
    clock2 => 0,
);
my $label = Gtk2::Label->new();
$label->set_markup( html($default) );
my $button      = Gtk2::Button->new('count');
my $checkbutton = Gtk2::CheckButton->new('forward');
$button->set_tooltip_text('click for start/pause counting');
my $reset       = Gtk2::Button->new('reset');
my $editbutton  = Gtk2::Button->new("..");
my $editbutton2 = Gtk2::Button->new("..");
my $label2      = Gtk2::Label->new();
$label2->set_markup( html($default2) );
my $button2 = Gtk2::Button->new('count');
$button2->set_tooltip_text('click for start/pause counting');
my $reset2 = Gtk2::Button->new('reset');

init_counter(
    button     => $button,
    'reset'    => $reset,
    clock      => 'clock',
    label      => $label,
    default    => $default,
    text       => "now it's time to take a break",
    editbutton => $editbutton,
);
init_counter(
    button     => $button2,
    'reset'    => $reset2,
    clock      => 'clock2',
    label      => $label2,
    default    => $default2,
    text       => "return to work, lazy boy!",
    editbutton => $editbutton2,
);
my $box     = Gtk2::HBox->new;
my $editbox = Gtk2::VBox->new;
$editbox->add($editbutton);
$box->add($label);
$box->add($editbox);
$box->add($button);
$box->add($reset);

my $box2     = Gtk2::HBox->new;
my $editbox2 = Gtk2::VBox->new;
$editbox2->add($editbutton2);
$box2->add($label2);
$box2->add($editbox2);
$box2->add($button2);
$box2->add($reset2);

my $vbox = Gtk2::VBox->new;
$vbox->add($box);
$vbox->add($box2);
$vbox->add($checkbutton);
$window->add($vbox);
$checkbutton->signal_connect( toggled => sub { print "xxx"; } );
$window->show_all;
Gtk2->main;

sub init_counter {
    my %p = @_;
    $p{editbutton}
      ->signal_connect( 'clicked' => sub { freeze(%p); valorize_label(%p) } );
    $p{button}->signal_connect(
        clicked => sub {
            if ( fmt_dt2( $p{label}->get_text ) == 0 ) {
                &reset(%p);
            }
            elsif ( $counters{ $p{clock} } ) {
                freeze(%p);
            }
            else {
                $counters{ $p{clock} } =
                  Glib::Timeout->add( 1000, sub { &decrement(%p); } );
            }
        }
    );

    $p{'reset'}->signal_connect(
        clicked => sub {
            &reset(%p);
        }
    );
}

sub decrement {
    my %p = @_;
    my $c = fmt_dt2( $p{label}->get_text );
    my $line;
    if ( $checkbutton->get_active() ) {
        ;
        $line = ++$c;
    }
    else {

        $line = --$c;
    }
    $p{label}->set_markup( html($line) );
    if ( $c == 0 ) {
        my $alert  = Gtk2::Window->new('toplevel');
        my $button = Gtk2::Button->new('dismiss');

        #if fortune is available a richer version is available
        my $message =
          &isfortuneavailable ? $p{text} . "\n" . &randomfortune : $p{text};
        my $label = Gtk2::Label->new($message);
        $label->set_selectable(1);
        my $vbox = Gtk2::VBox->new;
        $vbox->add($label);
        $vbox->add($button);
        $alert->add($vbox);
        $button->signal_connect( clicked => sub { $alert->destroy() } );
        $alert->show_all;
    }
    return ( $c > 0 ) ? 1 : 0;
}

sub reset {
    my %p = @_;
    if ( $checkbutton->get_active() ) {

        $p{label}->set_markup( html( 1, 'red' ) );
    }
    else {
        $p{label}->set_markup( html( $p{default}, 'red' ) );
    }
    freeze(%p) if ( $counters{ $p{clock} } );
}

sub freeze {
    my %p = @_;
    Glib::Source->remove( $counters{ $p{clock} } );
    $counters{ $p{clock} } = 0;
}

sub html {
    my $value = shift;
    my $color = shift || 'green';
    my $string=fmt_dt($value);
    my ($hour,$rest)=$string=~/(\d+:)(\d+:\d+)/;
    return "<span font_family ='Eli 5.0b' foreground='$color' background='black' size='20000' >$hour</span><span font_family ='Eli 5.0b' foreground='$color' background='black' size='50000' >$rest</span>";
}

sub fmt_dt {
    return DateTime::Format::Duration->new(
        pattern   => '%H:%M:%S',
        normalize => 1
    )->format_duration( DateTime::Duration->new( seconds => shift ) );
}

sub fmt_dt2 {
    return DateTime::Format::Duration->new( pattern => '%s', )
      ->format_duration(
        DateTime::Duration->new( hours => $1, minutes => $2, seconds => $3 ) )
      if shift =~ /(\d+):(\d+):(\d+)/;
}

sub isfortuneavailable {
    return `which fortune` ? 1 : 0;
}

sub randomfortune {
    return `fortune`;
}

sub valorize_label {
    my %p      = @_;
    my $window = Gtk2::Window->new('toplevel');
    my $button = Gtk2::Button->new('_update');
    my $label  = Gtk2::Label->new('enter new value');
    my $entry  = Gtk2::Entry->new();
    $entry->append_text( $p{label}->get_text );
    my $vbox = Gtk2::VBox->new;
    $vbox->add($label);
    $vbox->add($entry);
    $vbox->add($button);
    $window->add($vbox);
    $button->signal_connect(
        clicked => sub {

            #double conversion is needed
            $p{label}->set_markup( html( fmt_dt2( $entry->get_text ) ) );
            $window->destroy;
        }
    );
    $window->show_all;
}
__END__

What's new
0.2.2 bugfix: clickling when 00:00:00 didn't reset. Changed font for hour, now smaller.
0.2.1 can get over hour
0.2 can count up
0.1 only count down
