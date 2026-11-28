/// Where the home tab's list goes when a channel search starts with the list scrolled to [offset]: no further down than
/// [collapsedAt], where the big title has become the title pill and the search is stuck below it. The results then
/// start right below the search instead of scrolled out of view, or, when they are few, below a search that the list
/// can't stay scrolled to.
double searchStartOffset(double offset, double collapsedAt) => offset > collapsedAt ? collapsedAt : offset;

/// How much empty room the home tab's list needs below the search results, which take up [above] of the list (with
/// everything above them) in a [viewport] that high, to scroll as far as [collapsedAt]: the list is then at least a
/// viewport and [collapsedAt] long. None once the results are that long by themselves.
double searchRoomBelowResults({required double viewport, required double above, required double collapsedAt}) {
  final room = viewport + collapsedAt - above;
  return room > 0.0 ? room : 0.0;
}
