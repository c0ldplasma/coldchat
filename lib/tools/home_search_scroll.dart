/// Where the home tab's list goes when a channel search starts with the list scrolled to [offset]: no further down than
/// [collapsedAt], where the big title has become the title pill and the search is stuck below it. The results then
/// start right below the search instead of scrolled out of view, or, when they are few, below a search that the list
/// can't stay scrolled to.
double searchStartOffset(double offset, double collapsedAt) => offset > collapsedAt ? collapsedAt : offset;
