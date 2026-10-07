import 'dart:math' as math;

const _accentFolds = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
};

final _wordSplit = RegExp(r'[\s\-_.+&/()]+');
final _spaces = RegExp(r'\s+');

String normalizeSearch(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final r in lower.runes) {
    final c = String.fromCharCode(r);
    b.write(_accentFolds[c] ?? c);
  }
  return b.toString().trim();
}

List<String> _words(String text) =>
    text.split(_wordSplit).where((w) => w.isNotEmpty).toList();

int scoreMatch(String query, String text) {
  if (query.isEmpty || text.isEmpty) return 0;
  if (text == query) return 1000;
  if (text.startsWith(query)) {
    return 900 - math.min(text.length - query.length, 60);
  }

  final words = _words(text);
  for (var i = 1; i < words.length; i++) {
    if (words[i].startsWith(query)) return 800 - math.min(i * 10, 60);
  }

  final idx = text.indexOf(query);
  if (idx >= 0) return 700 - math.min(idx, 60);

  if (query.length < 2) return 0;

  final sub = _subsequenceScore(query, text, words);
  if (sub > 0) return sub;

  return _typoScore(query, text, words);
}

int _subsequenceScore(String q, String text, List<String> words) {
  final starts = <int>{0};
  var offset = 0;
  for (final w in words) {
    final at = text.indexOf(w, offset);
    if (at >= 0) {
      starts.add(at);
      offset = at + w.length;
    }
  }

  var best = 0;
  for (final start in starts) {
    if (start >= text.length || text[start] != q[0]) continue;
    var ti = start;
    var last = start;
    var matched = 0;
    for (var qi = 0; qi < q.length; qi++) {
      final found = text.indexOf(q[qi], ti);
      if (found < 0) {
        matched = -1;
        break;
      }
      last = found;
      ti = found + 1;
      matched++;
    }
    if (matched != q.length) continue;
    final span = last - start + 1;
    if (span > q.length * 3 + 2) continue;
    final score = math.max(300, 600 - (span - q.length) * 10);
    if (score > best) best = score;
  }
  return best;
}

int _typoLimit(int len) {
  if (len < 4) return 0;
  if (len < 8) return 1;
  return 2;
}

int _typoScore(String q, String text, List<String> words) {
  final limit = _typoLimit(q.length);
  if (limit == 0) return 0;

  var best = limit + 1;
  for (final cand in <String>{text, ...words}) {
    for (final k in <int>{q.length - 1, q.length, q.length + 1}) {
      if (k <= 0) continue;
      final slice = k >= cand.length ? cand : cand.substring(0, k);
      final d = _osa(q, slice, limit);
      if (d < best) best = d;
    }
  }
  if (best > limit) return 0;
  return 450 - best * 60;
}

int _osa(String a, String b, int limit) {
  if ((a.length - b.length).abs() > limit) return limit + 1;
  final n = a.length;
  final m = b.length;
  var prev2 = List<int>.filled(m + 1, 0);
  var prev = List<int>.generate(m + 1, (j) => j);
  var cur = List<int>.filled(m + 1, 0);
  for (var i = 1; i <= n; i++) {
    cur[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= m; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = math.min(
        math.min(prev[j] + 1, cur[j - 1] + 1),
        prev[j - 1] + cost,
      );
      if (i > 1 &&
          j > 1 &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1)) {
        v = math.min(v, prev2[j - 2] + 1);
      }
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > limit) return limit + 1;
    final tmp = prev2;
    prev2 = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[m];
}

int _scoreOne(String q, String label, List<String> tags) {
  var best = scoreMatch(q, label);
  for (final t in tags) {
    if (t.isEmpty) continue;
    final s = t == q ? 950 : math.max(0, scoreMatch(q, t) - 80);
    if (s > best) best = s;
  }
  return best;
}

int scoreApp(
  String rawQuery,
  String label, [
  Iterable<String> tags = const <String>[],
]) {
  final q = normalizeSearch(rawQuery);
  if (q.isEmpty) return 0;
  final l = normalizeSearch(label);
  final t = tags.map(normalizeSearch).toList();

  final whole = _scoreOne(q, l, t);
  if (whole > 0) return whole;

  final tokens = q.split(_spaces);
  if (tokens.length < 2) return 0;
  var total = 0;
  for (final tok in tokens) {
    final s = _scoreOne(tok, l, t);
    if (s == 0) return 0;
    total += s;
  }
  return total ~/ tokens.length - 100;
}
