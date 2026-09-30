enum VerifyLevel {
  email,
  phone,
  breeder,
  veterinarian,
}

extension VerifyLevelX on VerifyLevel {
  int get rank => index + 1;

  String get label => switch (this) {
        VerifyLevel.email => 'E-post',
        VerifyLevel.phone => 'Telefon',
        VerifyLevel.breeder => 'Uppfödare',
        VerifyLevel.veterinarian => 'Veterinär',
      };

  String get hint => switch (this) {
        VerifyLevel.email => 'Bekräftas när du loggar in.',
        VerifyLevel.phone => 'Telefonnumret sparas på ditt konto.',
        VerifyLevel.breeder => 'Kennelnamn och dokument kan granskas av oss.',
        VerifyLevel.veterinarian => 'Legitimation och klinik kan granskas av oss.',
      };
}
