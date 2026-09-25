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
  'Karlskrona', 'Karlshamn', 'Ronneby', 'Ystad', 'Trelleborg', 'Landskrona',
  'Ängelholm', 'Hässleholm', 'Vänersborg', 'Skövde', 'Lidköping', 'Mariestad',
  'Piteå', 'Skellefteå', 'Boden', 'Kalix', 'Haparanda', 'Gällivare', 'Arvidsjaur',
];

const kAddresses = [
  'Stockholmsvägen 6, Upplands Väsby 194 61',
  'Drottninggatan 12, Stockholm 111 51',
  'Sveavägen 44, Stockholm 111 34',
  'Kungsgatan 8, Göteborg 411 19',
  'Avenyn 21, Göteborg 411 36',
  'Södra Förstadsgatan 4, Malmö 211 43',
  'Stora Torget 1, Uppsala 753 10',
  'Drottninggatan 2, Linköping 582 25',
  'Stora Gatan 15, Västerås 722 12',
  'Drottninggatan 29, Örebro 702 10',
  'Järnvägsgatan 10, Helsingborg 252 24',
  'Drottninggatan 18, Norrköping 602 24',
  'Östra Storgatan 9, Jönköping 553 21',
  'Renmarkstorget 5, Umeå 903 26',
  'Klostergatan 9, Lund 222 22',
  'Allégatan 11, Borås 503 32',
  'Storgatan 28, Sundsvall 852 30',
  'Drottninggatan 16, Gävle 803 11',
  'Storgatan 20, Växjö 352 30',
  'Drottninggatan 14, Karlstad 652 24',
  'Brogatan 7, Halmstad 302 43',
  'Prästgatan 27, Östersund 831 31',
  'Storgatan 3, Kiruna 981 31',
  'Storgatan 36, Luleå 972 31',
  'Storgatan 22, Kalmar 392 31',
  'Adelsgatan 11, Visby 621 57',
  'Storgatan 18, Falun 791 30',
  'Kungsgatan 5, Trollhättan 461 30',
  'Östra Långgatan 8, Upplands Väsby 194 31',
  'Dragonvägen 4, Upplands Väsby 194 33',
  'Centralvägen 2, Sollentuna 191 41',
  'Storgatan 1, Täby 183 34',
  'Frösundaleden 2, Solna 169 70',
  'Sturegatan 4, Sundbyberg 172 31',
  'Värmdövägen 20, Nacka 131 37',
  'Kommunalvägen 1, Huddinge 141 30',
];

const kBreeds = [
  'Golden retriever', 'Labrador retriever', 'Schäfer', 'Jämthund', 'Norsk älghund',
  'Border collie', 'Västgötaspets', 'Fransk bulldogg', 'Husky', 'Siberian husky',
  'Rottweiler', 'Cocker spaniel', 'Tax', 'Shetland sheepdog', 'Dobermann',
  'Pudel', 'Pomeranian', 'Tysk spets / Pomeranian', 'Zwergspitz', 'Basset hound',
  'Australisk herdehund', 'Bernersennen', 'Whippet', 'Cavalier king charles spaniel',
  'Norsk buhund', 'Beagle', 'Boxer', 'Jack russell terrier', 'Chihuahua',
  'Dansk-svensk gårdshund', 'Drever', 'Hamiltonstövare', 'Finsk spets',
  'Karelsk björnhund', 'Samojed', 'Alaskan malamute', 'Akita', 'Shiba',
  'Malteser', 'Bichon frisé', 'Rhodesian ridgeback', 'Vizsla', 'Weimaraner',
  'Dalmatiner', 'Cane corso', 'Staffordshire bullterrier', 'Amstaff',
  'Mops', 'Shih tzu', 'Yorkshireterrier', 'Papillon', 'Blandras',
];

String _fold(String s) => s
    .toLowerCase()
    .replaceAll('å', 'a')
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o');

List<String> suggest(String query, List<String> source) {
  final q = _fold(query.trim());
  if (q.isEmpty) return source.take(8).toList();
  return source.where((s) => _fold(s).contains(q)).take(8).toList();
}
