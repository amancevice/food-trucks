Meteor.startup(function () {

  // DAYS
  if (Days.find().count() === 0) {
    var days = [
      {pos: 0, name: 'Sunday'},
      {pos: 1, name: 'Monday'},
      {pos: 2, name: 'Tuesday'},
      {pos: 3, name: 'Wednesday'},
      {pos: 4, name: 'Thursday'},
      {pos: 5, name: 'Friday'},
      {pos: 6, name: 'Saturday'}
    ];
    for (var i=0; i < days.length; i++)
      Days.insert({name: days[i].name, pos: days[i].pos});
  }

  // MEALS
  if (Meals.find().count() === 0) {
    var meals = [
      {pos: 0, name: 'Breakfast'},
      {pos: 1, name: 'Lunch'},
      {pos: 2, name: 'Dinner'},
      {pos: 3, name: 'Late Night'}
    ];
    for (var i=0; i < meals.length; i++)
      Meals.insert({name: meals[i].name, pos: meals[i].pos});
  }
});
