import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/twitch/twitch_profile.dart';

class ChannelInfo extends Cubit<TwitchProfile?> {
  ChannelInfo() : super(null);
}
