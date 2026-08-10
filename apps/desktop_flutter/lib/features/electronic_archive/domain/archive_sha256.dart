/// Small, dependency-free SHA-256 implementation for archive preflight.
///
/// This is intentionally limited to hashing bytes already selected on the
/// desktop. Authoritative checksum verification still belongs to the backend.
String archiveSha256Hex(List<int> input) {
  final bytes = <int>[for (final value in input) value & 0xff];
  final bitLength = bytes.length * 8;
  bytes.add(0x80);
  while (bytes.length % 64 != 56) {
    bytes.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    bytes.add((bitLength >> shift) & 0xff);
  }

  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;
  final schedule = List<int>.filled(64, 0);

  for (var offset = 0; offset < bytes.length; offset += 64) {
    for (var index = 0; index < 16; index++) {
      final byteOffset = offset + index * 4;
      schedule[index] = _uint32(
        (bytes[byteOffset] << 24) |
            (bytes[byteOffset + 1] << 16) |
            (bytes[byteOffset + 2] << 8) |
            bytes[byteOffset + 3],
      );
    }
    for (var index = 16; index < 64; index++) {
      final s0 = _rotateRight(schedule[index - 15], 7) ^
          _rotateRight(schedule[index - 15], 18) ^
          (schedule[index - 15] >> 3);
      final s1 = _rotateRight(schedule[index - 2], 17) ^
          _rotateRight(schedule[index - 2], 19) ^
          (schedule[index - 2] >> 10);
      schedule[index] = _uint32(
        schedule[index - 16] + s0 + schedule[index - 7] + s1,
      );
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    var f = h5;
    var g = h6;
    var h = h7;
    for (var index = 0; index < 64; index++) {
      final upperSigma1 = _rotateRight(e, 6) ^
          _rotateRight(e, 11) ^
          _rotateRight(e, 25);
      final choice = (e & f) ^ ((~e) & g);
      final temporary1 = _uint32(
        h + upperSigma1 + choice + _roundConstants[index] + schedule[index],
      );
      final upperSigma0 = _rotateRight(a, 2) ^
          _rotateRight(a, 13) ^
          _rotateRight(a, 22);
      final majority = (a & b) ^ (a & c) ^ (b & c);
      final temporary2 = _uint32(upperSigma0 + majority);

      h = g;
      g = f;
      f = e;
      e = _uint32(d + temporary1);
      d = c;
      c = b;
      b = a;
      a = _uint32(temporary1 + temporary2);
    }

    h0 = _uint32(h0 + a);
    h1 = _uint32(h1 + b);
    h2 = _uint32(h2 + c);
    h3 = _uint32(h3 + d);
    h4 = _uint32(h4 + e);
    h5 = _uint32(h5 + f);
    h6 = _uint32(h6 + g);
    h7 = _uint32(h7 + h);
  }

  return [h0, h1, h2, h3, h4, h5, h6, h7]
      .map((value) => value.toRadixString(16).padLeft(8, '0'))
      .join();
}

int _uint32(int value) => value & 0xffffffff;

int _rotateRight(int value, int count) =>
    _uint32((value >> count) | (value << (32 - count)));

const _roundConstants = <int>[
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
];
