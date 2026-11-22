import '../../api/twitch/helix_api.dart';
import '../../api/twitch/twitch_profile.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/twitch/token_data.dart';
import '../../data/twitch/user_data.dart';
import 'account_session.dart';
import 'client.dart';

/// The Helix lookups the user card, the chatter list and the login need, so the widgets don't talk to Helix
/// themselves. They run as [AccountSession.apiTokenData] unless a token is given.
extension ClientLookups on Client {
  /// Whether [profileOf] can return anything: profiles come from Helix, which needs a login.
  bool get canLookUpProfiles => session.apiTokenData != null;

  /// Everything the user card shows about [login], or null without a login, for an unknown user or when the
  /// request fails.
  Future<TwitchProfile?> profileOf(String login) async {
    final tokenData = session.apiTokenData;
    if (tokenData == null) return null;
    try {
      return await helix.forToken(tokenData).profile(login);
    } catch (_) {
      return null;
    }
  }

  /// The profile pictures of [logins] by login, in one batched request per 100. Empty without a login or when the
  /// request fails.
  Future<Map<String, String>> profileImageUrls(List<String> logins) async {
    final tokenData = session.apiTokenData;
    if (tokenData == null || logins.isEmpty) return const {};
    try {
      final users = await helix.forToken(tokenData).usersByLogin(logins);
      return {for (final user in users) user.login: user.profileImageUrl};
    } catch (_) {
      return const {};
    }
  }

  /// The user [tokenData] belongs to, as Helix reports it. Used to verify a fresh login.
  Future<UserData> userDataFor(TokenData tokenData) => helix.forToken(tokenData).userData();

  /// Helix as the active account of [accounts], or null without one.
  HelixApi? helixAsActive(AccountRepository accounts) {
    final account = accounts.active;
    return account == null ? null : helix.forToken(account.tokenData);
  }
}
