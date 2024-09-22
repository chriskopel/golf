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
    """
    Calculate the USGA Handicap Index for a player based on course information.

    Returns:
    float: The player's Handicap Index.
    """
    score_differentials = []

    try:
        # Parse JSON data from the request
        data = request.get_json()
        submissions = data.get('submissions', [])

        print('Received Submissions:')
        for idx, submission in enumerate(submissions, start=1):
            # Split and assign each component from the course string
            course_parts = submission['course'].split(' -- ')
            tee_gender_parts = submission['teeGender'].split(' -- ')

            # Parse the values
            golf_course = course_parts[0].strip()
            city = course_parts[1].strip()
            state = course_parts[2].strip()
            tee = tee_gender_parts[0].strip()
            # yardage = tee_gender_parts[1].strip() # this is used to help the user in the selection on the front end, don't need it here
            gender = tee_gender_parts[2].strip()
            score = float(submission['score'].strip())


            # Look up course rating and slope rating from the DataFrame
            course_data = df_gc[(df_gc['Course Name'] == golf_course) &
                                (df_gc['City'] == city) &
                                (df_gc['State'] == state) &
                                (df_gc['Tee Name'] == tee) &
                                (df_gc['Gender'] == gender) &
                                (df_gc['Back (9)'] != '/')]

            if not course_data.empty:
                course_rating = course_data.iloc[0]['Course Rating™']
                slope_rating = course_data.iloc[0]['Slope Rating®']

                # Calculate score differential
                differential = (113 / slope_rating) * (score - course_rating)
                score_differentials.append(differential)
            else:
                print(f"Course information not found for: {golf_course}, {city}, {state}, {tee}")


        # Sort the score differentials and select the lowest 8 if there are at least 20 rounds
        # differentials = score_differentials # in case we want to show the user the raw differentials
        score_differentials.sort()
        num_differentials = min(8, len(score_differentials))
        best_differentials = score_differentials[:num_differentials]

        # Calculate the average of the selected differentials and apply the 0.96 multiplier
        if best_differentials:
            average_differential = sum(best_differentials) / num_differentials
            handicap_index = round(average_differential * 0.96,2)
        else:
            handicap_index = None

        print(handicap_index)

        # Return a success response with parsed data
        return jsonify({
            'status': 'success',
            'message': 'Data parsed successfully',
            'parsed_data': handicap_index
        }), 200

    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500




### Run app
if __name__ == '__main__':
    app.run(debug=True)