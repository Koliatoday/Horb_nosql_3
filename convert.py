"""Converting data from .dat file to the csv format"""

import csv

# movies.dat: MovieID::Title::Genres
with open('data/movies.dat', encoding='latin-1') as f_in, \
     open('import/movies.csv', 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['movieId', 'title', 'genres'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts)

# ratings.dat: UserID::MovieID::Rating::Timestamp
with open('data/ratings.dat', encoding='latin-1') as f_in, \
     open('import/ratings.csv', 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['userId', 'movieId', 'rating', 'timestamp'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts)

# users.dat: UserID::Gender::Age::Occupation::Zip
with open('data/users.dat', encoding='latin-1') as f_in, \
     open('import/users.csv', 'w', newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(['userId', 'gender', 'age', 'occupation'])
    for line in f_in:
        parts = line.strip().split('::')
        writer.writerow(parts[:4])  # zip not used
