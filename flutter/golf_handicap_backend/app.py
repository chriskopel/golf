from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

### Load data
# Load golf course data from CSV into a DataFrame
df_gc = pd.read_csv('data/usga_scrdb_aug_2024.csv')


### Functions
def calculate_handicap_index_from_courses(df_gc, scores, course_info):
    """
    Calculate the USGA Handicap Index for a player based on course information.

    Parameters:
    df_gc (pd.DataFrame): DataFrame containing course information.
    scores (list of float): List of adjusted gross scores for each round.
    course_info (list of tuple): List of tuples containing course name, city, state, tee name, and gender.

    Returns:
    float: The player's Handicap Index.
    """
    score_differentials = []

    for i, (course_name, city, state, tee_name, gender) in enumerate(course_info):
        # Look up course rating and slope rating from the DataFrame
        course_data = df_gc[(df_gc['Course Name'] == course_name) &
                            (df_gc['City'] == city) &
                            (df_gc['State'] == state) &
                            (df_gc['Tee Name'] == tee_name) &
                            (df_gc['Gender'] == gender) &
                            (df_gc['Back (9)'] != '/')]

        if not course_data.empty:
            course_rating = course_data.iloc[0]['Course Rating™']
            slope_rating = course_data.iloc[0]['Slope Rating®']

            # Calculate score differential
            differential = (113 / slope_rating) * (scores[i] - course_rating)
            score_differentials.append(differential)
        else:
            print(f"Course information not found for: {course_name}, {city}, {state}, {tee_name}")

    # Sort the score differentials and select the lowest 8 if there are at least 20 rounds
    score_differentials.sort()
    num_differentials = min(8, len(score_differentials))
    best_differentials = score_differentials[:num_differentials]

    # Calculate the average of the selected differentials and apply the 0.96 multiplier
    if best_differentials:
        average_differential = sum(best_differentials) / num_differentials
        handicap_index = average_differential * 0.96
    else:
        handicap_index = None

    return handicap_index



### Flask
# Flask route to calculate handicap
@app.route('/calculate-handicap', methods=['POST'])
def calculate_handicap():
    data = request.json

    scores = data.get('scores', [])
    course_info = data.get('course_info', [])

    if not scores or not course_info:
        return jsonify({'error': 'Scores or course info missing'}), 400

    # Calculate the handicap index using the provided scores and course info
    handicap_index = calculate_handicap_index_from_courses(df_gc, scores, course_info)

    if handicap_index is not None:
        return jsonify({'handicap_index': handicap_index}), 200
    else:
        return jsonify({'error': 'Could not calculate handicap index'}), 500

if __name__ == '__main__':
    app.run(debug=True)


# Flask route to fetch golf courses
@app.route('/api/golf-courses', methods=['GET'])
def get_golf_courses():
    # Extract unique golf courses
    df_temp = df_gc.head(1000)
    courses = df_temp['Course Name'].unique().tolist()
    return jsonify(courses)



# # Flask route to test if data is coming through
# @app.route('/api/preview-data', methods=['GET'])
# def preview_data():
#     courses = df_gc['Course Name'].unique().tolist()

#     # Return a preview of the data as JSON
#     data_preview = courses[:100]
#     return jsonify(data_preview)



if __name__ == '__main__':
    app.run(debug=True)