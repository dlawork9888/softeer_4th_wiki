# import field
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np
import datetime
import os
import sqlite3

### Logger
# 로그 파일 => etl_project_log.txt
def log_message(message):
    if not 'etl_project_log.txt' in os.listdir():
        with open('etl_project_log.txt', 'w') as f:
            f.write("ETL Project Log\n")
            f.write("=" * 20 + "\n")
    with open('etl_project_log.txt', 'a') as f:
        current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write(f"{current_time} - {message}\n")

### get_gdp_from_wiki
def get_gdp_from_wiki():
    
    log_message('Starting ETL process for GDP data from Wiki')

    # 페이지에 요청을 떄려보자
    response = requests.get('https://en.wikipedia.org/wiki/List_of_countries_by_GDP_%28nominal%29')
    log_message('Request to wiki for GDP data completed')

    # html파서로 파싱 !
    soup = BeautifulSoup(response.content, 'html.parser')
    log_message('Request to wiki for GDP data completed')

    # GDP 테이블을 찾아보자 !
    # 해당 페이지에는 테이블이 하나 밖에 없음
    # 클래스명이 wikitable인 태그
    gdp_table = soup.find('table', {'class': 'wikitable'})
    log_message('GDP table found in HTML content')

    # 각 행을 파싱 <- <tr> 태그
    rows = gdp_table.find_all('tr')

    # df 만들 데이터 준비
    countries = []
    gdps = []
    years = []

    for row in rows[3:]:
        eles = row.find_all('td')  # td태그 달린 애들 중 [0][1]만 쓸 것임 !
        # 나라 추가
        country = eles[0].text.strip()
        countries.append(country)
        # gdp, 연도 추가
        # - 가 있음 ! => 적절한 처리(아래)
        if eles[1].text.strip().replace(',', '') != '—':
            gdp_forecast = int(eles[1].text.strip().replace(',', ''))
            gdps.append(gdp_forecast)
            year = int(eles[2].text.strip()[-4:])
            years.append(year)
        else:  # 측정이 안됐을 경우
            log_message(f'empty GDP value - {country}')
            gdps.append(np.nan)
            years.append(np.nan)
    
    log_message('GDP data extraction from table rows completed')


    # 데이터프레임 생성
    gdp_df = pd.DataFrame(
        {
            'Country': countries,
            'GDP': gdps,
            'Year': years
        }
    )
    log_message('DataFrame creation completed')

    # gdp는 Million단위로 되어있음 => Billon단위로 수정
    gdp_df["GDP"] = (gdp_df["GDP"]/1000).round(2)
    log_message('GDP values converted from million to billion USD')

    log_message('ETL process for GDP data completed successfully')

    return gdp_df


### get_region_from_wiki
def get_region_from_wiki():

    log_message('Starting ETL process for region data from Wikipedia')

    # 페이지 정보 요청
    response = requests.get('https://en.wikipedia.org/wiki/List_of_countries_and_territories_by_the_United_Nations_geoscheme')
    log_message('Request to wiki for region data completed')
    
    # HTML 파싱
    soup = BeautifulSoup(response.content, 'html.parser')
    log_message('HTML parsing completed')

    # region table 찾기
    region_table = soup.find('table', {'class': 'wikitable'})
    log_message('Region table found in HTML content')
    
    # 테이블 parsing
    rows = region_table.find_all('tr')
    log_message('Region table rows parsed')

    # 데이터 추출, df 만들기 준비
    countries = []
    geograpical_subregions = []
    intermediary_regions = []
    continental_regions = []

    for row in rows[1:]:
        eles = row.find_all('td')
        # 나라
        country = eles[0].text.strip()
        countries.append(eles[0].text.strip())
        # geographical subregion
        geograpical_subregion = eles[1].text.strip()
        if geograpical_subregion == '—':
            geograpical_subregion = np.nan
        geograpical_subregions.append(geograpical_subregion)
        # intermediary region
        intermediary_region = eles[2].text.strip()
        if intermediary_region == '—':
            intermediary_region = np.nan
        intermediary_regions.append(intermediary_region)
        # continental region
        continental_region = eles[3].text.strip()
        if continental_region == '—':
            continental_region = np.nan
        continental_regions.append(continental_region)

    log_message('Region data extraction from table rows completed')

    # df 만들기
    region_df = pd.DataFrame(
        {
            'Country': countries,
            'Geograpical Subregion': geograpical_subregions,
            'Intermediary Region': intermediary_regions,
            'Continental Region': continental_regions
        }
    )
    log_message('DataFrame creation for region data completed')

    # gdf_df의 country행을 on으로 join했을 떄, 매칭 안되는 나라 있음
    not_matched_countries = ['United States', 'United Kingdom', 'France', 'Russia',
        'South Korea', 'Turkey', 'Taiwan', 'Vietnam', 'Iran', 'Hong Kong',
        'Czech Republic', 'Venezuela', 'Ivory Coast', 'Tanzania',
        'DR Congo', 'Myanmar', 'Macau', 'Bolivia', 'Palestine', 'Moldova',
        'Brunei', 'Congo', 'Laos', 'North Korea', 'Kosovo', 'Syria',
        'Eswatini', 'Cape Verde', 'Zanzibar', 'East Timor', 'Sint Maarten',
        'São Tomé and Príncipe', 'Micronesia']
    # 매칭되는 대륙만 좀 추가해주자
    continents = ['Americas', 'Europe', 'Europe', 'Europe',
                'Asia', 'Asia', 'Asia', 'Asia', 'Asia', 'Asia',
                'Europe', 'Americas', 'Africa', 'Africa',
                'Africa', 'Asia', 'Asia', 'Americas', 'Asia', 'Europe',
                'Asia', 'Africa', 'Asia', 'Asia', 'Europe', 'Asia',
                'Africa', 'Africa', 'Africa', 'Asia', 'Americas',
                'Africa', 'Oceania']
    new_df = pd.DataFrame(
        {
            'Country': not_matched_countries,
            'Geograpical Subregion': [np.nan for _ in range(len(continents))],
            'Intermediary Region': [np.nan for _ in range(len(continents))],
            'Continental Region': continents
        }
    )
    log_message('Created DataFrame for unmatched countries with their continents')

    # join시에 매칭될 수 있도록 region_df에 concat
    region_df = pd.concat([region_df, new_df], ignore_index=True)
    log_message('Concatenated unmatched countries to the region DataFrame')

    log_message('ETL process for region data completed successfully')

    return region_df

### 저장할 파일의 이름 결정 함수
# 혹시 이름이 있으면 _1, _2 ... 이런식으로
# 저장할 이름을 반환
# filename은 이름.확장자
# 디렉터리는 현재 디렉터리 기준
def get_unique_filename(filename): 
    # 없으면 그냥 이름 그대로 쓰자
    if not os.path.exists(filename):
        return filename
    else: # 있으면
        base, ext = os.path.splitext(filename)
        counter = 1
        new_filename = f"{base}_{counter}{ext}"
        while os.path.exists(new_filename): # 있으면 카운터 계속 올리기
            counter += 1
            new_filename = f"{base}_{counter}{ext}"
        return new_filename
    
if __name__ == "__main__":
    ### DB 적용
    # 연결 (없으면 db생성)
    log_message("Connecting to the database.")
    conn = sqlite3.connect('World_Economies.db')

    # 크롤링된 정보 가져오기
    gdp_df = get_gdp_from_wiki()
    log_message("Fetching GDP data from wiki completed")
    region_df = get_region_from_wiki()
    log_message("Fetching region data from wiki completed")

    # 위 두 df를 테이블로 저장(있다면 갈아치우기)
    gdp_df.to_sql('GDP', conn, if_exists='replace', index=False)
    region_df.to_sql('Region', conn, if_exists='replace', index=False)
    log_message("Saving GDP, region data to the database as GDP, Region table completed")

    # 저장된 두 테이블 Country를 기준으로 LEFT OUTER JOIN 하는 쿼리
    log_message("Joining GDP and region tables using str query")
    query = '''
    SELECT L.Country AS COUNTRY, L.GDP AS GDP_USD_BILLION, R."Continental Region" AS REGION
    FROM GDP L
    LEFT OUTER JOIN Region R
    ON L.Country = R.Country
    '''
    # 쿼리의 결과를 불러오자 !
    #cursor = conn.cursor()
    #cursor.execute(query)
    joined_df = pd.read_sql_query(query, conn)
    # 해당 df를 'Countries_by_GDP'라는 테이블로 저장(있으면 갈아치우기)
    joined_df.to_sql('Countries_by_GDP',conn, if_exists='replace', index=False)
    log_message("Executing join query completed, the table was saved as 'Countries_by_GDP'")



    ### Countries_by_GDP 에서 GDP_USD_BILLION가 100 이상 나라만 출력
    log_message("Querying countries with GDP >= 100 billion USD.")
    query = """
    SELECT * 
    FROM Countries_by_GDP
    WHERE GDP_USD_BILLION >= 100;
    """
    countries_gdp_over_100 = pd.read_sql_query(query, conn)
    print(countries_gdp_over_100)
    log_message("The result of query was printed on console.")
    
    ### 지역 별 TOP 5 출력
    log_message("Querying top 5 countries by GDP in each region.")
    query = """
    SELECT COUNTRY, GDP_USD_BILLION, REGION, RANK 
    FROM (
        SELECT COUNTRY, GDP_USD_BILLION, REGION, ROW_NUMBER() OVER (PARTITION BY REGION ORDER BY GDP_USD_BILLION) AS RANK
        FROM Countries_by_GDP)
    WHERE RANK <= 5;
    """
    top5s = pd.read_sql_query(query, conn)
    print(top5s)
    log_message("The result of query was printed on console.")

    conn.close()
    log_message("The database connection was closed")
    