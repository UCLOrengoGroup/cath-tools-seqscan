#!/usr/bin/env perl
use inc::Module::Install 1.02;

name 'Cath-Tools-Seqscan';

all_from 'lib/Cath/Tools/Seqscan.pm';

requires 'HTTP::Tiny' => '';
requires 'IO::String';
requires 'JSON::MaybeXS' => '';
requires 'Log::Dispatch';
requires 'Moo' => '';
requires 'MooX::Options' => '';
requires 'namespace::autoclean' => '';
requires 'Path::Tiny' => '';
requires 'Params::Validate' => '';
requires 'Try::Tiny' => '';
requires 'Type::Library' => '';
requires 'Type::Utils' => '';
requires 'Types::Standard' => '';
requires 'Text::LineFold';
requires 'Type::Tiny';
requires 'URI';

WriteAll;
