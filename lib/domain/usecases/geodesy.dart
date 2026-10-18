import 'dart:math' as math;

/// Geodesic distance on the WGS-84 ellipsoid.
///
/// Implemented here in pure Dart rather than delegating to
/// `Geolocator.distanceBetween` because the domain layer must not import
/// plugins — and because a deterministic implementation can be tested against
/// published geodetic fixtures, which a platform call cannot.
///
/// Uses Vincenty's inverse formula (accurate to ~0.5 mm), falling back to a
/// great-circle approximation for near-antipodal pairs where Vincenty is known
/// not to converge.

/// WGS-84 semi-major axis, metres.
const double _a = 6378137.0;

/// WGS-84 flattening.
const double _f = 1 / 298.257223563;

/// WGS-84 semi-minor axis, metres.
const double _b = (1 - _f) * _a;

const int _maxIterations = 200;
const double _convergence = 1e-12;

/// Geodesic distance between two coordinates, in metres.
///
/// Handles the awkward cases the naive formula gets wrong: identical points,
/// the antimeridian, the poles, and antipodal pairs.
double geodesicDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  // Exactly coincident: skip the iteration entirely (sinSigma would be 0).
  if (lat1 == lat2 && lon1 == lon2) return 0;

  final phi1 = _radians(lat1);
  final phi2 = _radians(lat2);

  // Normalising the longitude difference into [-pi, pi] is what makes a
  // dateline crossing measure the short way round rather than the long way.
  final l = _normaliseLongitudeDelta(_radians(lon2 - lon1));

  final tanU1 = (1 - _f) * math.tan(phi1);
  final cosU1 = 1 / math.sqrt(1 + tanU1 * tanU1);
  final sinU1 = tanU1 * cosU1;

  final tanU2 = (1 - _f) * math.tan(phi2);
  final cosU2 = 1 / math.sqrt(1 + tanU2 * tanU2);
  final sinU2 = tanU2 * cosU2;

  var lambda = l;
  double sinLambda = 0;
  double cosLambda = 0;
  double sinSigma = 0;
  double cosSigma = 0;
  double sigma = 0;
  double cosSqAlpha = 0;
  double cos2SigmaM = 0;
  var converged = false;

  for (var i = 0; i < _maxIterations; i++) {
    sinLambda = math.sin(lambda);
    cosLambda = math.cos(lambda);

    final sinSigmaSq = math.pow(cosU2 * sinLambda, 2) +
        math.pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2);
    sinSigma = math.sqrt(sinSigmaSq.toDouble());

    // Coincident after normalisation.
    if (sinSigma == 0) return 0;

    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma = math.atan2(sinSigma, cosSigma);

    final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha = 1 - sinAlpha * sinAlpha;

    // On an equatorial line cosSqAlpha is 0 and cos2SigmaM is undefined; the
    // standard treatment is to set it to zero.
    cos2SigmaM =
        cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;

    final c = _f / 16 * cosSqAlpha * (4 + _f * (4 - 3 * cosSqAlpha));
    final lambdaPrev = lambda;
    lambda = l +
        (1 - c) *
            _f *
            sinAlpha *
            (sigma +
                c *
                    sinSigma *
                    (cos2SigmaM +
                        c * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));

    if ((lambda - lambdaPrev).abs() < _convergence) {
      converged = true;
      break;
    }
  }

  // Near-antipodal: Vincenty's inverse does not converge. Fall back to the
  // spherical great-circle distance, which is within ~0.3% there — far better
  // than returning NaN or a wildly wrong number.
  if (!converged) {
    return _greatCircleDistance(phi1, phi2, l);
  }

  final uSq = cosSqAlpha * (_a * _a - _b * _b) / (_b * _b);
  final aa = 1 +
      uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
  final bb = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));

  final deltaSigma = bb *
      sinSigma *
      (cos2SigmaM +
          bb /
              4 *
              (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                  bb /
                      6 *
                      cos2SigmaM *
                      (-3 + 4 * sinSigma * sinSigma) *
                      (-3 + 4 * cos2SigmaM * cos2SigmaM)));

  return _b * aa * (sigma - deltaSigma);
}

/// Spherical fallback for antipodal pairs, using the mean Earth radius.
double _greatCircleDistance(double phi1, double phi2, double deltaLambda) {
  const meanRadius = 6371008.8;
  final dPhi = phi2 - phi1;
  final h = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(deltaLambda / 2) *
          math.sin(deltaLambda / 2);
  return meanRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

/// Wraps a longitude delta into [-pi, pi] so crossing the antimeridian is
/// measured the short way.
double _normaliseLongitudeDelta(double radians) {
  var r = radians;
  while (r > math.pi) {
    r -= 2 * math.pi;
  }
  while (r < -math.pi) {
    r += 2 * math.pi;
  }
  return r;
}

double _radians(double degrees) => degrees * math.pi / 180;
