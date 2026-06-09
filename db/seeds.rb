# Clear existing data
puts "Cleaning database..."
UserBoard.destroy_all
Problem.destroy_all
BoardLayout.destroy_all
Board.destroy_all
User.destroy_all

# Create users
puts "Creating users..."
user1 = User.create!(
  email: "bob@bob.com",
  password: "password",
  password_confirmation: "password"
)

user2 = User.create!(
  email: "climber2@example.com",
  password: "password",
  password_confirmation: "password"
)

# Seed built-in grading systems
Rake::Task["grading_systems:seed"].invoke
font_system = GradingSystem.find_by!(name: "Font", system_type: "built_in")

# Create board
puts "Creating board..."
board = Board.create!(
  name: "Home Woody",
  description: "40 degree overhanging home board with various holds",
  grading_system: font_system
)

# Associate users with board
puts "Associating users with board..."
UserBoard.create!(user: user1, board: board)
UserBoard.create!(user: user2, board: board)

# Create board layout
puts "Creating board layout..."
layout = BoardLayout.new(
  name: "Current Setup v1",
  board: board
)
layout.image_layout.attach(
  io: File.open(Rails.root.join('db/seeds/IMG_20250906_165115294.jpg')),
  filename: "IMG_20250906_165115294.jpg",
  content_type: 'image/jpeg'
)
layout.save!

# Set as default for user1
user1.update(default_grading_system: font_system)

# Create problems
puts "Creating problems..."
Problem.create!(
  name: "Crimson Eagle Summit",
  grade: "6c",
  board_layout: layout,
  start_holds: [ { x: 50, y: 85 } ],
  hand_holds: [ { x: 40, y: 65 }, { x: 55, y: 45 }, { x: 45, y: 28 } ],
  finish_holds: [ { x: 50, y: 12 } ]
)

Problem.create!(
  name: "Midnight Wolf Traverse",
  grade: "7b",
  board_layout: layout,
  start_holds: [ { x: 30, y: 88 } ],
  hand_holds: [ { x: 35, y: 70 }, { x: 50, y: 55 }, { x: 60, y: 38 }, { x: 70, y: 22 } ],
  foot_holds: [ { x: 28, y: 60 }, { x: 40, y: 45 } ],
  finish_holds: [ { x: 75, y: 10 } ]
)

# Create exercise types and exercises for user1
puts "Creating exercise types and exercises..."

# Core exercises
plank = ExerciseType.create!(user: user1, name: "Plank", unit: "seconds", category: :core)
hollow_hold = ExerciseType.create!(user: user1, name: "Hollow Hold", unit: "seconds", category: :core)

# Upper body exercises
pull_ups = ExerciseType.create!(user: user1, name: "Pull-ups", unit: "reps", category: :upper_body)
push_ups = ExerciseType.create!(user: user1, name: "Push-ups", unit: "reps", category: :upper_body)

# Finger exercises
hang_20mm = ExerciseType.create!(user: user1, name: "20mm Edge Hang", unit: "seconds", category: :finger)
max_hang = ExerciseType.create!(user: user1, name: "Max Hang (20mm)", unit: "kg added", category: :finger)

# Lower body exercises
squats = ExerciseType.create!(user: user1, name: "Squats", unit: "reps", category: :lower_body)
pistol_squats = ExerciseType.create!(user: user1, name: "Pistol Squats", unit: "reps", category: :lower_body)

# Cardio exercises
running = ExerciseType.create!(user: user1, name: "Running", unit: "km", category: :cardio)

# Generate exercises over the past 8 weeks
8.weeks.ago.to_date.upto(Date.current) do |date|
  # Skip some days randomly for realistic data
  next if rand < 0.6

  performed_at = date.to_datetime + rand(6..20).hours

  # Core (2-3 times per week)
  if date.wday.in?([ 1, 3, 5 ]) && rand > 0.3
    Exercise.create!(exercise_type: plank, value: rand(45..90), performed_at: performed_at)
    Exercise.create!(exercise_type: hollow_hold, value: rand(30..60), performed_at: performed_at) if rand > 0.5
  end

  # Upper body (2-3 times per week)
  if date.wday.in?([ 1, 2, 4 ]) && rand > 0.3
    Exercise.create!(exercise_type: pull_ups, value: rand(8..15), performed_at: performed_at)
    Exercise.create!(exercise_type: push_ups, value: rand(20..40), performed_at: performed_at) if rand > 0.4
  end

  # Finger training (2 times per week)
  if date.wday.in?([ 2, 5 ]) && rand > 0.4
    Exercise.create!(exercise_type: hang_20mm, value: rand(7..12), performed_at: performed_at)
    Exercise.create!(exercise_type: max_hang, value: rand(10..25), performed_at: performed_at) if rand > 0.5
  end

  # Lower body (1-2 times per week)
  if date.wday == 3 && rand > 0.4
    Exercise.create!(exercise_type: squats, value: rand(15..30), performed_at: performed_at)
    Exercise.create!(exercise_type: pistol_squats, value: rand(5..10), performed_at: performed_at) if rand > 0.6
  end

  # Cardio (1-2 times per week)
  if date.wday.in?([ 0, 6 ]) && rand > 0.5
    Exercise.create!(exercise_type: running, value: rand(3.0..8.0).round(1), performed_at: performed_at)
  end
end

exercise_count = Exercise.count

puts "Seeding complete!"
puts "Created:"
puts "- 2 users (bob@bob.com and climber2@example.com)"
puts "- 1 board: #{board.name}"
puts "- 1 layout: #{layout.name}"
puts "- 2 problems"
puts "- 9 exercise types across 5 categories"
puts "- #{exercise_count} exercises over the past 8 weeks"
