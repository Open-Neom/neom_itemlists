import 'dart:async';
import 'package:neom_commons/core/domain/model/app_item.dart';
import 'package:neom_commons/core/domain/model/item_list.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_itemlists/itemlists/utils/constants/app_spotify_constants.dart';
import 'package:spotify/spotify.dart';

class SpotifySearch {

  final logger = AppUtilities.logger;
  final spotify = SpotifyApi(AppSpotifyConstants.getSpotifyCredentials());

  Map<String, AppItem> songs = {};
  Map<String, Itemlist> giglists = {};

  Future<Map<String, AppItem>> searchSongs(String searchParam) async {
    logger.d("Searching for songs");

    try {
      var searchData = await spotify.search
          .get(searchParam.toLowerCase(),
            types: [SearchType.track])
          .first(20)
          .catchError((err) {
            logger.e(err.toString());
            return err;
          });

      logger.i("Retrieving songs from Spotify");
      loadSongsFromSpotify(searchData);

    } catch (e) {
      logger.e(e.toString());
    }

    return songs;

  }


  Future<Map<String, Itemlist>> searchPlaylists(String searchParam) async {
    logger.d("Searching for playlists");

    try {
      var searchData = await spotify.search
          .get(searchParam.toLowerCase(),
            types: [SearchType.playlist])
          .first(50);

      logger.i("Retrieving playlists from Spotify");
      loadPlaylistsFromSpotify(searchData);

    } catch (e) {
      logger.e(e.toString());
    }

    return giglists;
  }


  Future<void> loadSongsFromSpotify(List<Page<dynamic>> searchData) async {

    try {
      for (var page in searchData) {
        for (var item in page.items!) {
          if (item is Track) {
            AppItem song = AppItem.mapTrackToSong(item);
            songs[song.id] = song;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

  }


  void loadPlaylistsFromSpotify(List<Page<dynamic>> searchData) async {

    try {
      for (var page in searchData) {
        for (var item in page.items!) {
          if (item is Playlist) {
            Itemlist giglist = await Itemlist.mapPlaylistToItemlist(item);
            giglists[giglist.id] = giglist;
          } else if (item is PlaylistSimple) {
            Itemlist giglist = Itemlist.mapPlaylistSimpleToItemlist(item);
            giglists[giglist.id] = giglist;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${giglists.length} playlists retrieved");
  }

  Future<Artist> loadArtistDetails(String artistId) async {
    logger.d("Retrieving Details for artistId $artistId");
    Artist artist = Artist();

    try {
      artist = await spotify.artists.get(artistId);
    } catch (e) {
      logger.e(e.toString());
    }

    return artist;
  }

  Future<List<AppItem>> loadSongsFromPlaylist(String playlistId) async {
    logger.d("Loading songs from playlist $playlistId");
    List<AppItem> playlistSongs = [];
    Playlist playlist = Playlist();

    try {
      playlist = await spotify.playlists.get(playlistId);

      if(playlist.tracks != null) {
        playlistSongs = await AppItem.mapTracksToSongs(playlist.tracks!);
      }
    } catch (e) {
      logger.e(e.toString());
    }

    return playlistSongs;
  }

}

