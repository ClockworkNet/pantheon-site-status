import 'dart:convert';
import 'dart:io';

import 'package:console/console.dart';

import 'evaluator.dart';
import 'models/site.dart';
import 'pantheon.dart';
import 'wordpress.dart';

/// Site information manager.
///
/// This class manages the gathering and saving of Pantheon
/// website information.
class SinfoManager {
  /// Pantheon organization ID.
  final String pantheonOrgId;

  /// Path used for JSON results file.
  final String resultsPath;

  /// Used to access data in Pantheon.
  Pantheon pantheon;

  /// Default constructor.
  SinfoManager({this.pantheonOrgId, this.resultsPath});

  /// Gather data about an organization's Pantheon sites.
  Future<File> sitesFile() {
    Console.init();
    pantheon = Pantheon(pantheonOrgId: pantheonOrgId);
    return _sitesFromPantheon().then(_enrichSites).then(_saveSitesAsJson);
  }

  /// Get all the organization's sites from Pantheon while
  /// printing out progress.
  Future<List<Site>> _sitesFromPantheon() {
    print('Retrieving sites from Pantheon...');
    final loading = LoadingBar();
    loading.start();

    return pantheon.fetchSites().then((sites) {
      loading.stop('Sites retrieved from Pantheon: ${sites.length}');
      return sites;
    });
  }

  /// Process of list of sites from Pantheon and gather
  /// addional data for each site that is not frozen.
  Future<List<Site>> _enrichSites(List<Site> sites) async {
    print('Gathering data for each site...');

    // Display a progress bar less than the width of the terminal.
    Console.adapter = NarrowAdapter();
    final progress = ProgressBar(complete: sites.length);

    var completed = 0;
    var enrichedSites = <Site>[];

    for (var site in sites) {
      if (site.isActive) {
        await _enrichSite(site);
        Evaluator().evaluateSite(site);
        enrichedSites.add(site);
      }
      completed++;
      progress.update(completed);
    }

    print('\nEnriched sites: ${enrichedSites.length}');
    return enrichedSites;
  }

  /// Enrich a site with data from around the world.
  Future<Site> _enrichSite(Site site) async {
    final evaluator = Evaluator();
    final wordPress = WordPress();

    site.phpVersion = await pantheon.fetchPhpVersion(site.pantheonName);
    site.liveUrl = await pantheon.fetchLiveUrl(site.pantheonName);
    site.newRelicStatus = await pantheon.fetchNewRelicStatus(site.pantheonName);
    site.upstreamStatus = await pantheon.fetchUpstreamStatus(site.pantheonName);
    site.phpStability = evaluator.phpStability(site.phpVersion);

    if (site.cmsName == 'wordpress') {
      site.cmsVersion = await pantheon.fetchWordPressVersion(site.pantheonName);
      site.cmsStability =
          await wordPress.fetchVersionStability(site.cmsVersion);
      site.plugins = await pantheon.fetchWordPressPlugins(site.pantheonName);
    }

    return site;
  }

  /// Save a List of sites as a JSON file.
  Future<File> _saveSitesAsJson(List<Site> sites) {
    print('Saving results...');
    final loading = LoadingBar();
    loading.start();

    return File(resultsPath)
        .create(recursive: true)
        .then((file) => file.writeAsString(json.encode(sites)).then((file) {
              loading.stop('Results saved to file $resultsPath');
              return file;
            }));
  }
}

/// This adapter is used to control the width of the progress bar.
class NarrowAdapter extends StdioConsoleAdapter {
  @override
  int get columns => 50;
}
