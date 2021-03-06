require 'linalg'

users = { 1 => "Ben", 2 => "Tom", 3 => "John", 4 => "Fred" }
m = Linalg::DMatrix[
           #Ben, Tom, John, Fred
            [5,5,0,5], # season 1
            [5,0,3,4], # season 2
            [3,4,0,3], # season 3
            [0,0,5,3], # season 4
            [5,4,4,5], # season 5
            [5,4,5,5]  # season 6
            ]

# Compute the SVD Decomposition
u, s, vt = m.singular_value_decomposition
vt = vt.transpose

# Take the 2-rank approximation of the Matrix
#   - Take first and second columns of u  (6x2)
#   - Take first and second columns of vt (4x2)
#   - Take the first two eigen-values (2x2)
u2 = Linalg::DMatrix.join_columns [u.column(0), u.column(1)]
v2 = Linalg::DMatrix.join_columns [vt.column(0), vt.column(1)]
eig2 = Linalg::DMatrix.columns [s.column(0).to_a.flatten[0,2], s.column(1).to_a.flatten[0,2]]

# Here comes Bob, our new user
bob = Linalg::DMatrix[[5,5,0,0,0,5]]
bobEmbed = bob * u2 * eig2.inverse

# Compute the cosine similarity between Bob and every other User in our 2-D space
user_sim, count = {}, 1
v2.rows.each { |x| 
    user_sim[count] = (bobEmbed.transpose.dot(x.transpose)) / (x.norm * bobEmbed.norm)
    count += 1 
  }

# Remove all users who fall below the 0.90 cosine similarity cutoff and sort by similarity
similar_users = user_sim.delete_if {|k,sim| sim < 0.9 }.sort {|a,b| b[1] <=> a[1] } 
similar_users.each { |u| printf "%s (ID: %d, Similarity: %0.3f) \n", users[u[0]], u[0], u[1]  }

# We'll use a simple strategy in this case:
#   1) Select the most similar user
#   2) Compare all items rated by this user against your own and select items that you have not yet rated
#   3) Return the ratings for items I have not yet seen, but the most similar user has rated
similarUsersItems = m.column(similar_users[0][0]-1).transpose.to_a.flatten
myItems = bob.transpose.to_a.flatten

not_seen_yet = {}
myItems.each_index { |i|
  not_seen_yet[i+1] = similarUsersItems[i] if myItems[i] == 0 and similarUsersItems[i] != 0 
}

printf "\n %s recommends: \n", users[similar_users[0][0]]
not_seen_yet.sort {|a,b| b[1] <=> a[1] }.each { |item|
  printf "\tSeason %d .. I gave it a rating of %d \n", item[0], item[1]
}

print "We've seen all the same seasons, bugger!" if not_seen_yet.size == 0
