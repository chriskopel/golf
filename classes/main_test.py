import requests
from bs4 import BeautifulSoup
import pandas as pd



########################################################################
#### Begin scraping class

class ScrapeNCRDB:

    # Set base url
    base_url = "https://ncrdb.usga.org/courseTeeInfo?CourseID="


    # Init vars
    def __init__(self, course_id):
        course_url = self.base_url + str(course_id)
        response = requests.get(course_url)
        self.soup = BeautifulSoup(response.content, 'html.parser')
        self.course_id = course_id

        # init error flag
        self.error_flag = 0

        # Check for the specific error message
        error_message = self.soup.find('h2', class_='text-danger errorHandler')
        if error_message and "An error occurred. If this problem persists, contact USGA Handicap Department." in error_message.get_text():
            self.error_flag = 1



    # Method to scrape USGA NCRDB
    def return_course_df(self):

        if self.error_flag == 1:
            return None
        
        else:
            ## Start with course metadata
            # Find metadata table
            metadata_table = self.soup.find('table', id='gvCourseTees')

            # Extract info
            course_name = metadata_table.find_all('td')[0].get_text(strip=True).split(" - ")[0]
            city = metadata_table.find_all('td')[1].get_text(strip=True)
            state = metadata_table.find_all('td')[2].get_text(strip=True)


            ## Course data
            table = self.soup.find('table',id='gvTee')

            # Header info
            header_row = table.find('tr', class_='tableRows')
            headers = [th.get_text(strip=True) for th in header_row.find_all('th')]

            # Course info
            rows = table.find_all('tr')[1:]  # Skip the header row



            # Extract data from each row
            data = []
            for row in rows:
                cells = row.find_all('td')
                row_data = [cell.get_text(strip=True) for cell in cells]
                data.append(row_data)

            if len(headers) == 16:
                data = [sublist[:-2] for sublist in data]


            ## Consolidate all into df
            df = pd.DataFrame(data, columns=headers)
            if len(headers) == 18:
                df = df.drop(columns=('CH'))
                df = df.loc[:, df.columns != '']

            # Add the extracted values as new columns to the beginning of the DataFrame
            df.insert(0, 'Course Name', course_name)
            df.insert(1, 'City', city)
            df.insert(2, 'State', state)

            # Add ts
            df['usga_course_id'] = self.course_id
            df['timestamp'] = pd.Timestamp.now()

            return df