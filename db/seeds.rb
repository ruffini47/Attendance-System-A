# coding: utf-8

User.create!(name: "管理者",
             email: "admin@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true,
             superior: true)
             
User.create!(name: "上長A",
             email: "superior-A@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: true)

User.create!(name: "上長B",
             email: "superior-B@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false,
             superior: true)

User.create!(name: "テストマン",
             email: "testman@email.com",
             password: "password",
             admin: false,
             affiliation: "テスター",
             superior: false)


#60.times do |n|
#  name  = Faker::Name.name
#  email = "sample-#{n+1}@email.com"
#  password = "password"
#  User.create!(name: name,
#               email: email,
#               password: password,
#               password_confirmation: password)
#end
