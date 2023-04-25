
import 'package:neom_commons/core/app_flavour.dart';
import 'package:spotify/spotify.dart';

class AppSpotifyConstants {

  static const String redirectUrl = "https://www.gigmeout.io/spotify_auth.html";
  static const String scope = "app-remote-control,user-modify-playback-state,"
      " user-library-read,user-top-read, playlist-read-collaborative,"
      " playlist-read-private";
  static const List<String> scopes = [
    "app-remote-control",
    "user-modify-playback-state",
    "user-library-read",
    "user-top-read",
    "playlist-read-collaborative",
    "playlist-read-private"];
  static const String meUrl = 'https://api.spotify.com/v1/me';

  static SpotifyApiCredentials getSpotifyCredentials({String accessToken = ""}) {
    return SpotifyApiCredentials(
        AppFlavour.getSpotifyClientId(),
        AppFlavour.getSpotifyClientSecret(),
        accessToken: accessToken,
        scopes: scopes,
    );
  }
}
