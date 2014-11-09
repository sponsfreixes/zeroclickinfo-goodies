package DDG::Goodie::Uptime;
# Given an uptime percentage, display various average downtime durations 

use DDG::Goodie;
use Time::Duration;
use Time::Seconds;
with 'DDG::GoodieRole::NumberStyler';

zci answer_type => "uptime";
zci is_cached   => 1;

name "Uptime";
description "Given an uptime percentage, display various average downtime durations";
primary_example_queries "uptime 99,99%", "uptime 99.99%";
secondary_example_queries "uptime of 99.9998%";
category "calculations";
topics "computing";
code_url "https://github.com/duckduckgo/zeroclickinfo-goodies/blob/master/lib/DDG/Goodie/Uptime/Uptime.pm";
attribution github => ["YouriAckx", "Youri Ackx"],
            web => ["http://ackx.net/", "Youri Ackx"],
            twitter => "YouriAckx";

# Triggers
triggers start => "uptime", "uptime of";

# Near zero duration messages
my $JUST_NOW_MSG = "just now";                          # from Time::Duration
my $LESS_THAN_ONE_SECOND_MSG = "Less than one second";  # from us


# Compute the downtime string durations (year, month, day)
# for the given uptime (must be btw 0 and 1)
sub compute_durations {
    my $downtime_percentage = 1 - $_[0];
    my $a_day = ONE_DAY;
    my $a_month = ONE_MONTH;
    my $a_year = ONE_YEAR;
    
    return (
        fix_just_now(duration($a_year * $downtime_percentage)),
        fix_just_now(duration($a_month * $downtime_percentage)),
        fix_just_now(duration($a_day * $downtime_percentage))
    );
}


# Given a duration, replace "just now" emitted by Time::Duration
# by "Less than one second" when applicable,
# or return the duration itself otherwise.
sub fix_just_now {
    my $duration = $_[0];
    return $duration ne $JUST_NOW_MSG ? $duration : $LESS_THAN_ONE_SECOND_MSG;
}


# Format response as text
sub format_text {
    my ($uptime_percentage, $downtime_year, $downtime_month, $downtime_day) = @_;
    my $text = "Uptime of " . $uptime_percentage . "\n";
    
    if ($downtime_year eq $LESS_THAN_ONE_SECOND_MSG) {
        $text .= "No downtime or less than a second during a year\n";
        return $text;
    }
    
    $text .= $downtime_day . " downtime per day\n";
    $text .= $downtime_month . " downtime per month\n";
    $text .= $downtime_year . " downtime per year\n";
    return $text;
}


# Format response as HTML
sub format_html {
    my ($uptime_percentage, $downtime_year, $downtime_month, $downtime_day) = @_;
    my $html = '<div class="zci__caption">Uptime of ' . $uptime_percentage . "</div>";

    if ($downtime_year eq $LESS_THAN_ONE_SECOND_MSG) {
        $html .= '<div class="secondary--text">No downtime or less than a second during a year</div>';
        return $html;
    }

    $html .= '<div class="secondary--text">' . $downtime_day . " downtime per day</div>";
    $html .= '<div class="secondary--text">' . $downtime_month . " downtime per month</div>";
    $html .= '<div class="secondary--text">' . $downtime_year . " downtime per year</div>";
    return $html;
}


# Handle statement
handle remainder => sub {
	return unless $_;               # Guard against "no answer"
    return unless s/%$//;           # Query should end with '%'. Test and remove it
    s/\s+//g;                       # Delete the whitespaces

    # Look for something that "looks like a number"
    my $number_string = $_;
    my $number_re = number_style_regex();
    $number_string =~ qr/($number_re)/;

    # Get an object that can handle the number
    my $styler = number_style_for($number_string);
    return unless $styler;  # might not be supported
    my $perl_number = $styler->for_computation($number_string);
    my $clean_query = $styler->for_display($perl_number) . '%';
    
    # Query value must be btw 0 and 100
    return unless $perl_number >= 0 && $perl_number < 100;
    
    my ($year, $month, $day) = compute_durations($perl_number / 100);
    my $text = format_text($clean_query, $year, $month, $day);
    my $html = format_html($clean_query, $year, $month, $day);
    
	return $text, html => $html;
};

1;
