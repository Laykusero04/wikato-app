class Dialect {
  const Dialect({
    required this.code,
    required this.name,
    required this.region,
  });

  final String code;
  final String name;
  final String region;
}

const dialects = <Dialect>[
  Dialect(code: 'tl', name: 'Tagalog', region: 'Luzon · National'),
  Dialect(code: 'ceb', name: 'Cebuano', region: 'Visayas · Mindanao'),
  Dialect(code: 'ilo', name: 'Ilocano', region: 'Northern Luzon'),
  Dialect(code: 'hil', name: 'Hiligaynon', region: 'Western Visayas'),
  Dialect(code: 'war', name: 'Waray', region: 'Eastern Visayas'),
  Dialect(code: 'bcl', name: 'Bikol', region: 'Bicol Region'),
];

const defaultDialectCode = 'tl';

String dialectNameFor(String? code) {
  if (code == null) return 'Tagalog';
  for (final d in dialects) {
    if (d.code == code) return d.name;
  }
  return 'Tagalog';
}
