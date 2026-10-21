import 'package:local_auth/local_auth.dart';

import '../../l10n/strings_id.dart';

const kunciSidikJariAktif = 'sidik_jari_aktif';

Future<bool> sidikJariTersedia() async {
  try {
    final bio = LocalAuthentication();
    final terdaftar = await bio.getAvailableBiometrics();
    return await bio.canCheckBiometrics &&
        await bio.isDeviceSupported() &&
        (terdaftar.contains(BiometricType.fingerprint) ||
            terdaftar.contains(BiometricType.strong) ||
            terdaftar.contains(BiometricType.weak));
  } catch (_) {
    return false;
  }
}

String pesanGalatSidikJari(String code) {
  switch (code) {
    case 'NotEnrolled':
      return Strings.sidikJariBelumTerdaftar;
    case 'LockedOut':
      return Strings.sidikJariTerkunciSementara;
    case 'PermanentlyLockedOut':
      return Strings.sidikJariTerkunci;
    case 'PasscodeNotSet':
      return Strings.sidikJariButuhKunciLayar;
    case 'NotAvailable':
    default:
      return Strings.sidikJariTidakTersedia;
  }
}
