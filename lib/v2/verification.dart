enum VerifyLevel {
  email,
  phone,
  governmentId,
  breeder,
  veterinarian,
}

extension VerifyLevelX on VerifyLevel {
  int get rank => index + 1;

  String get label => switch (this) {
        VerifyLevel.email => 'Nivå 1 · E-post',
        VerifyLevel.phone => 'Nivå 2 · Telefon',
        VerifyLevel.governmentId => 'Nivå 3 · BankID (kommer)',
        VerifyLevel.breeder => 'Nivå 4 · Uppfödare',
        VerifyLevel.veterinarian => 'Nivå 5 · Veterinär',
      };

  String get hint => switch (this) {
        VerifyLevel.email => 'Bekräftad när du loggar in.',
        VerifyLevel.phone => 'SMS-kod. Aktiveras när Twilio/Supabase Auth är på.',
        VerifyLevel.governmentId => 'BankID kräver avtal. Inte påslaget än.',
        VerifyLevel.breeder => 'Kennelnamn + uppladdade papper granskas av oss.',
        VerifyLevel.veterinarian => 'Legitimation + klinik, manuell granskning.',
      };
}
