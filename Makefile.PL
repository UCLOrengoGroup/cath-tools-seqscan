#!/usr/bin/env perl
use inc::Module::Install 1.02;

name 'Cath-Tools-Seqscan';

all_from 'lib/Cath/Tools/Seqscan.pm';

requires 'Moo' => '';
requires 'MooX::Options' => '';
requires 'Path::Class' => '';
requires 'REST::Client' => '';
requires 'URI';
requires 'JSON::Any';
requires 'Log::Dispatch';

WriteAll;
