import 'dart:io';

/// This script processes command-line arguments and
/// then creates an instance of sinfo using the supplied command-line
/// arguments.

import 'package:args/args.dart';
import 'package:sinfo/sinfo_manager.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();
  _addArguments(parser);
  final results = parser.parse(arguments);

  if (results['help']) {
    print('Sinfo is a tool for producing a JSON file containing detailed '
        'information about websites managed by Pantheon.');
    print(parser.usage);
    return;
  }

  final sinfo = SinfoManager(
    pantheonOrgId: results['org'],
    resultsPath: results['results-file'],
  );

  await sinfo.sitesFile();

  exit(0);
}

/// Add arguments (options and flags) to the parser.
void _addArguments(ArgParser parser) {
  parser.addOption(
    'org',
    abbr: 'o',
    help: 'Pantheon organization ID.\n'
        "It can be found in the URL of your organization's Pantheon dashboard.",
    valueHelp: 'ID',
    defaultsTo: 'fffc93bd-ab50-42e2-8219-676ac29837d0',
  );

  parser.addOption(
    'results-file',
    abbr: 'f',
    help: 'Path for final results JSON file.',
    valueHelp: 'path',
    defaultsTo: './data/sites.json',
  );

  parser.addFlag('help',
      negatable: false,
      abbr: 'h',
      defaultsTo: false,
      help: 'Display help message');
}
