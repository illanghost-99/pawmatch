/// PawMatch AI Vet — summarizer, never a clinician.
class AiVet {
  static const disclaimer =
      'Jag är inte veterinär och ställer ingen diagnos. Jag sammanfattar bara det du själv skrivit eller laddat upp. Vid oro: kontakta legitimerad veterinär eller Djursjukvårdsupplysningen 090-490 31 40.';

  static String reply(String q) {
    final t = q.toLowerCase();
    if (t.contains('diagnos') || t.contains('vad har min hund') || t.contains('canc')) {
      return '$disclaimer\n\nJag får inte säga vilken sjukdom det är. Boka veterinär om hunden är slö, inte äter, kräks, haltar eller andas ansträngt.';
    }
    if (t.contains('vaccin')) {
      return '$disclaimer\n\nVanlig grundvaccination i Sverige täcker bland annat valpsjuka, hepatit och parvovirus. Intervall bestäms av veterinär. Ladda upp journalen under Hälsa så kan jag räkna upp datumen du själv angett.';
    }
    if (t.contains('dna') || t.contains('genetik') || t.contains('pra') || t.contains('hd')) {
      return '$disclaimer\n\nDNA-tester och HD/ED är beslutsunderlag för avel, inte facit. SKK publicerar officiella resultat i Avelsdata. PawMatch visar bara det du laddat upp och det vi granskat.';
    }
    if (t.contains('vikt') || t.contains('övervikt') || t.contains('overvikt')) {
      return '$disclaimer\n\nVikt följs bäst mot rasens normalspann och hullbedömning. Plottra vikten i hälsotidslinjen. Snabb viktminskning eller -uppgång ska veterinär bedöma.';
    }
    if (t.contains('valp') && (t.contains('mask') || t.contains('avmask'))) {
      return '$disclaimer\n\nAvmaskning av valp sker enligt veterinärs schema. Använd inte slumpmässiga doser från nätet.';
    }
    return '$disclaimer\n\nFråga gärna om vaccinationer, journaler, DNA-begrepp eller när det är dags att ringa veterinär. Jag förklarar begrepp — jag behandlar inte.';
  }
}
