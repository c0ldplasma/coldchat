import 'package:coldchat/tools/home_search_scroll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a search started further down goes to where the search is stuck at the top', () {
    expect(searchStartOffset(900.0, 56.0), 56.0);
  });

  test('a search started with the title still showing stays there', () {
    expect(searchStartOffset(0.0, 56.0), 0.0);
    expect(searchStartOffset(30.0, 56.0), 30.0);
    expect(searchStartOffset(56.0, 56.0), 56.0);
  });
}
