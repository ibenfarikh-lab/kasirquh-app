enum ModeDering { bawaan, khas, hening }

ModeDering modeDeringPelanggan(String? pilihan) => switch (pilihan) {
      'khas' => ModeDering.khas,
      'hening' => ModeDering.hening,
      _ => ModeDering.bawaan,
    };

ModeDering modeDeringAdmin(String? suara) => switch (suara) {
      'mimi' => ModeDering.khas,
      'silent' => ModeDering.hening,
      _ => ModeDering.bawaan,
    };

String idKanalDering(ModeDering mode) => switch (mode) {
      ModeDering.khas => 'kasirquh_khas',
      ModeDering.hening => 'kasirquh_hening',
      ModeDering.bawaan => 'kasirquh',
    };
