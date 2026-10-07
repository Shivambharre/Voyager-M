enum FilterAction { allow, block }

class FilterResult {
  const FilterResult({required this.action, this.reason});

  const FilterResult.allow({String? reason})
    : this(action: FilterAction.allow, reason: reason);

  const FilterResult.block({String? reason})
    : this(action: FilterAction.block, reason: reason);

  final FilterAction action;
  final String? reason;

  bool get shouldBlock => action == FilterAction.block;
}
