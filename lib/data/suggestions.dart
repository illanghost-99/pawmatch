const kCities = [
  'Stockholm', 'Göteborg', 'Malmö', 'Uppsala', 'Linköping', 'Västerås', 'Örebro',
  'Helsingborg', 'Norrköping', 'Jönköping', 'Umeå', 'Lund', 'Borås', 'Sundsvall',
  'Gävle', 'Växjö', 'Karlstad', 'Halmstad', 'Östersund', 'Åre', 'Kiruna', 'Luleå',
  'Kalmar', 'Visby', 'Skara', 'Falun', 'Trollhättan', 'Uddevalla', 'Kristianstad',
  'Upplands Väsby', 'Sollentuna', 'Täby', 'Solna', 'Sundbyberg', 'Nacka', 'Huddinge',
  'Södertälje', 'Haninge', 'Botkyrka', 'Järfälla', 'Lidingö', 'Värmdö', 'Norrtälje',
  'Sigtuna', 'Vallentuna', 'Österåker', 'Ekerö', 'Tyresö', 'Danderyd', 'Vaxholm',
  'Mölndal', 'Partille', 'Kungälv', 'Lerum', 'Kungsbacka', 'Varberg', 'Falkenberg',
  'Eskilstuna', 'Nyköping', 'Strängnäs', 'Enköping', 'Västervik', 'Oskarshamn',
  'Karlskrona', 'Karlshamn', 'Ronneby', 'Ystad', 'Trelleborg', 'Lund', 'Landskrona',
  'Ängelholm', 'Hässleholm', 'Vänersborg', 'Skövde', 'Lidköping', 'Mariestad',
  'Piteå', 'Skellefteå', 'Boden', 'Kalix', 'Haparanda', 'Gällivare', 'Arvidsjaur',
];

const kBreeds = [
  'Golden retriever', 'Labrador retriever', 'Schäfer', 'Jämthund', 'Norsk älghund',
  'Border collie', 'Västgötaspets', 'Fransk bulldogg', 'Husky', 'Siberian husky',
  'Rottweiler', 'Cocker spaniel', 'Tax', 'Shetland sheepdog', 'Dobermann',
  'Pudel', 'Basset hound', 'Australisk herdehund', 'Bernersennen', 'Whippet',
  'Cavalier king charles spaniel', 'Norsk buhund', 'Beagle', 'Boxer',
  'Jack russell terrier', 'Chihuahua', 'Dansk-svensk gårdshund', 'Drever',
  'Hamiltonstövare', 'Finsk spets', 'Karelsk björnhund', 'Samojed',
  'Alaskan malamute', 'Akita', 'Shiba', 'Malteser', 'Bichon frisé',
  'Rhodesian ridgeback', 'Vizsla', 'Weimaraner', 'Dalmatiner', 'Cane corso',
  'Staffordshire bullterrier', 'Amerikansk staffordshire terrier', 'Amstaff',
  'Mops', 'Shih tzu', 'Yorkshireterrier', 'Papillon', 'Blandras',
];

List<String> suggest(String query, List<String> source) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return source.take(8).toList();
  return source.where((s) => s.toLowerCase().contains(q)).take(8).toList();
}
