import '../models.dart';

const sampleDogs = [
  DogProfile(id: '1', name: 'Kajsa', breed: 'Jämthund', age: 4, city: 'Östersund', lat: 63.1792, lng: 14.6357, bio: 'Jaktglad och trygg.', owner: 'Anna', tags: ['hunt', 'nature', 'friends']),
  DogProfile(id: '2', name: 'Bosse', breed: 'Schäfer', age: 5, city: 'Uppsala', lat: 59.8586, lng: 17.6389, bio: 'Tränad och social.', owner: 'Erik', tags: ['training', 'walks', 'friends']),
  DogProfile(id: '3', name: 'Elsa', breed: 'Golden retriever', age: 3, city: 'Stockholm', lat: 59.3293, lng: 18.0686, bio: 'Familjehund. Öppen för lek och kull.', owner: 'Mia', tags: ['play', 'puppies', 'city', 'friends'], intent: 'puppies'),
  DogProfile(id: '4', name: 'Rusk', breed: 'Jämthund', age: 6, city: 'Åre', lat: 63.3984, lng: 13.0815, bio: 'Fjällvan.', owner: 'Johan', tags: ['nature', 'hunt', 'walks']),
  DogProfile(id: '5', name: 'Nala', breed: 'Labrador', age: 2, city: 'Göteborg', lat: 57.7089, lng: 11.9746, bio: 'Vattenälskare.', owner: 'Lisa', tags: ['play', 'walks', 'friends']),
  DogProfile(id: '6', name: 'Eiro', breed: 'Border collie', age: 1, city: 'Falun', lat: 60.6065, lng: 15.6355, bio: 'Vill träna agility.', owner: 'Noah', tags: ['training', 'play']),
  DogProfile(id: '7', name: 'Saga', breed: 'Västgötaspets', age: 3, city: 'Skara', lat: 58.3866, lng: 13.4384, bio: 'Söker rasvänner.', owner: 'Kim', tags: ['friends', 'walks', 'puppies'], intent: 'puppies'),
];
