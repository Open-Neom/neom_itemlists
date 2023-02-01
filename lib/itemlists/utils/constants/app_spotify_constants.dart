
import 'package:spotify/spotify.dart';

class AppSpotifyConstants {

  /// spotify credentials
  static const String clientId = "4e12110673b14aa5948c165a3531eea3";
  static const String clientSecret = "f493d6dc556c49948ef487b9b5638633";
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
        clientId,
        clientSecret,
        accessToken: accessToken,
        scopes: scopes,
    );
  }
}
