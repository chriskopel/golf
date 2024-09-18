from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
from fuzzywuzzy import process



app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

### Load data
# Load golf course data from CSV into a DataFrame
df_gc = pd.read_csv('data/usga_scrdb_aug_2024.csv')
df_gc_unique = df_gc[['Course Name','City','State']].drop_duplicates()

# extract lists from df
gc_states = df_gc['State'].unique().tolist()
courses = sorted(df_gc['Course Name'].unique().tolist())




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
# Flask route to fetch filtered golf courses based on user input from search box
@app.route('/api/golf-courses', methods=['GET'])
def get_golf_courses():
    query = request.args.get('query', '')  # Get the query from the request
    if query:
        # Use fuzzy matching to find courses that match the query
        matched_courses = process.extract(query, courses, limit=10)
        # Extract just the course names (first element of each tuple)
        matched_courses = [course[0] for course in matched_courses]

        ## Now filter the pandas df accordingly
        df_course_result = df_gc_unique[df_gc_unique['Course Name'].isin(matched_courses)]
        result_course_list = df_course_result.apply(lambda row: f"{row['Course Name']} -- {row['City']} -- {row['State']}", axis=1).tolist()

    else:
        # Return 10 courses if no query is provided
        result_course_list = courses[3983:3993]
    return jsonify(result_course_list)



# Flask route to filter golf courses based on selected course
@app.route('/api/filter-course', methods=['POST'])
def filter_course():
    # Get the string sent from Flutter
    data = request.get_json()
    course_str = data.get('course')  # e.g., 'Colorado Golf Club, Parker, CO'


    # Split the string to extract the course name, city, and state
    course_name, city, state = [item.strip() for item in course_str.split('--')]

    # Filter the DataFrame based on the course name, city, and state
    filtered_df = df_gc[
        (df_gc['Course Name'] == course_name) &
        (df_gc['City'] == city) &
        (df_gc['State'] == state)
    ].reset_index(drop=True)
    filtered_df = filtered_df[['Tee Name','Length','Gender']].drop_duplicates()

    # Return the filtered results as a JSON response
    if not filtered_df.empty:
        # Convert the filtered DataFrame to a list format for the response
        filtered_data = filtered_df.apply(lambda row: f"{row['Tee Name']} -- {round(row['Length'])} -- {row['Gender']}", axis=1).tolist()
        return jsonify(filtered_data)
    else:
        return jsonify({'error': 'No matching course found'}), 404


# Flask route to accept submission and calc handicap
@app.route('/api/calculate-handicap', methods=['POST'])
def calculate_handicap():
    data = request.get_json()
    submissions = data.get('submissions', [])

    # Example processing logic for calculating handicap based on submissions
    # This is a placeholder - replace with your actual calculation logic
    total_scores = 0
    num_scores = len(submissions)

    if num_scores > 0:
        for submission in submissions:
            score = int(submission['score'])
            total_scores += score

        # Simple average as placeholder for handicap calculation
        average_score = total_scores / num_scores
        handicap = average_score  # Placeholder logic for handicap

        return jsonify({'handicap': handicap})
    else:
        return jsonify({'error': 'No submissions found'}), 400






### Run app
if __name__ == '__main__':
    app.run(debug=True)