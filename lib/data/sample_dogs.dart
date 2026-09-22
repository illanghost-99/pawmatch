import '../models.dart';

/// Bred svensk täckning — storstad, mindre ort och landsbygd.
const sampleDogs = [
  DogProfile(id: '1', name: 'Kajsa', breed: 'Jämthund', age: 4, city: 'Östersund', lat: 63.1792, lng: 14.6357, bio: 'Jaktglad och trygg i flock.', owner: 'Anna', tags: ['hunt', 'nature', 'friends'], intent: 'friends'),
  DogProfile(id: '2', name: 'Bosse', breed: 'Schäfer', age: 5, city: 'Uppsala', lat: 59.8586, lng: 17.6389, bio: 'Tränad, social, gillar skog.', owner: 'Erik', tags: ['training', 'walks', 'friends']),
  DogProfile(id: '3', name: 'Elsa', breed: 'Golden retriever', age: 3, city: 'Stockholm', lat: 59.3293, lng: 18.0686, bio: 'Mjuk familjehund. Öppen för lek och framtida kull.', owner: 'Mia', tags: ['play', 'puppies', 'city', 'friends'], intent: 'puppies', pedigreeStatus: ReviewStatus.approved, vaccineStatus: ReviewStatus.approved),
  DogProfile(id: '4', name: 'Rusk', breed: 'Jämthund', age: 6, city: 'Åre', lat: 63.3984, lng: 13.0815, bio: 'Fjällvan. Söker vandringskompis.', owner: 'Johan', tags: ['nature', 'hunt', 'walks']),
  DogProfile(id: '5', name: 'Nala', breed: 'Labrador', age: 2, city: 'Göteborg', lat: 57.7089, lng: 11.9746, bio: 'Vattenälskare och lekmaskin.', owner: 'Lisa', tags: ['play', 'walks', 'friends']),
  DogProfile(id: '6', name: 'Eiro', breed: 'Border collie', age: 1, city: 'Falun', lat: 60.6065, lng: 15.6355, bio: 'Högenergi. Vill träna agility.', owner: 'Noah', tags: ['training', 'play']),
  DogProfile(id: '7', name: 'Saga', breed: 'Västgötaspets', age: 3, city: 'Skara', lat: 58.3866, lng: 13.4384, bio: 'Liten herde. Söker rasvänner.', owner: 'Kim', tags: ['friends', 'walks', 'puppies'], intent: 'puppies'),
  DogProfile(id: '8', name: 'Tove', breed: 'Norsk älghund', age: 4, city: 'Umeå', lat: 63.8258, lng: 20.2630, bio: 'Nordlig jaktlust, lugn hemma.', owner: 'Sara', tags: ['hunt', 'nature']),
  DogProfile(id: '9', name: 'Max', breed: 'Fransk bulldogg', age: 2, city: 'Malmö', lat: 55.6050, lng: 13.0038, bio: 'Stadshund som älskar korta promenader.', owner: 'Alex', tags: ['city', 'friends', 'walks']),
  DogProfile(id: '10', name: 'Luna', breed: 'Husky', age: 3, city: 'Kiruna', lat: 67.8558, lng: 20.2253, bio: 'Drag och fjäll. Söker aktiva vänner.', owner: 'Pia', tags: ['nature', 'walks', 'friends']),
  DogProfile(id: '11', name: 'Bruno', breed: 'Rottweiler', age: 5, city: 'Västerås', lat: 59.6099, lng: 16.5448, bio: 'Stabil familjehund med tydlig träning.', owner: 'Omar', tags: ['training', 'friends']),
  DogProfile(id: '12', name: 'Molly', breed: 'Cocker spaniel', age: 4, city: 'Linköping', lat: 58.4108, lng: 15.6214, bio: 'Glad och social. Lekträffar välkomna.', owner: 'Hanna', tags: ['play', 'friends', 'walks']),
  DogProfile(id: '13', name: 'Olle', breed: 'Tax', age: 6, city: 'Visby', lat: 57.6348, lng: 18.2948, bio: 'Gotland. Korta ben, stort hjärta.', owner: 'Bo', tags: ['walks', 'friends']),
  DogProfile(id: '14', name: 'Freja', breed: 'Shetland sheepdog', age: 2, city: 'Karlstad', lat: 59.3793, lng: 13.5036, bio: 'Smart och mjuk. Öppen för träning.', owner: 'Ida', tags: ['training', 'play']),
  DogProfile(id: '15', name: 'Axel', breed: 'Dobermann', age: 3, city: 'Helsingborg', lat: 56.0465, lng: 12.6945, bio: 'Sportig. Söker seriös träningspartner.', owner: 'Tim', tags: ['training', 'walks']),
  DogProfile(id: '16', name: 'Iris', breed: 'Pudel', age: 5, city: 'Luleå', lat: 65.5842, lng: 22.1547, bio: 'Allergivänlig och aktiv i norr.', owner: 'Eva', tags: ['friends', 'city', 'walks']),
  DogProfile(id: '17', name: 'Sigge', breed: 'Basset hound', age: 7, city: 'Kalmar', lat: 56.6634, lng: 16.3566, bio: 'Lugn senior. Korta promenader.', owner: 'Rolf', tags: ['walks', 'friends']),
  DogProfile(id: '18', name: 'Nova', breed: 'Australisk herdehund', age: 2, city: 'Sundsvall', lat: 62.3908, lng: 17.3069, bio: 'Jobbhund i vardagen. Söker lek.', owner: 'Nina', tags: ['play', 'training', 'friends']),
  DogProfile(id: '19', name: 'Bamse', breed: 'Bernersennen', age: 4, city: 'Örebro', lat: 59.2753, lng: 15.2134, bio: 'Stor och snäll. Familjevän.', owner: 'Julia', tags: ['friends', 'walks']),
  DogProfile(id: '20', name: 'Zelda', breed: 'Whippet', age: 3, city: 'Jönköping', lat: 57.7826, lng: 14.1618, bio: 'Snabb på banan, mjuk i soffan.', owner: 'Leo', tags: ['play', 'city', 'friends']),
  DogProfile(id: '21', name: 'Stella', breed: 'Cavalier king charles', age: 1, city: 'Växjö', lat: 56.8777, lng: 14.8091, bio: 'Ung och nyfiken. Söker vänner.', owner: 'Moa', tags: ['friends', 'play']),
  DogProfile(id: '22', name: 'Tor', breed: 'Norsk buhund', age: 5, city: 'Gävle', lat: 60.6749, lng: 17.1413, bio: 'Vaktglad herde. Naturen föreallt.', owner: 'Kent', tags: ['nature', 'friends']),
  DogProfile(id: '23', name: 'Fia', breed: 'Beagle', age: 4, city: 'Halmstad', lat: 56.6745, lng: 12.8568, bio: 'Nosar sig fram längs kusten.', owner: 'Camilla', tags: ['walks', 'play', 'friends']),
  DogProfile(id: '24', name: 'Hugo', breed: 'Boxer', age: 3, city: 'Borås', lat: 57.7210, lng: 12.9401, bio: 'Energi och humor. Lek välkomnas.', owner: 'David', tags: ['play', 'training']),
];
