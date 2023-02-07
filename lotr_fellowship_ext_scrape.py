import re
from bs4 import BeautifulSoup
import requests
import csv

script = requests.get('https://www.councilofelrond.com/subject/the-fellowship-of-the-ring-extended-edition/').text
pre_soup = BeautifulSoup(script, 'lxml')
soup = BeautifulSoup(pre_soup.prettify(), 'lxml')
# print(soup.get_text())


# pattern = re.compile(r"[A-Za-z]+:{1}")
# matches = pattern.findall(soup.get_text())
# my_list = [matches]
# print(my_list)

## character speaking is bolded in html
# tags = soup.find_all("b")
# print(tags.string)
#trying to iterate with for
# lines = soup.find_all('b')
# for line in lines:
#      print(line)


#using regular expression with find_all, not working quite perfectly
# .text.replace(' ','')
# my_regex = re.compile(r"[A-Za-z]+:{1}")
# matched_strings = soup.find_all(text=my_regex)
# for matched_string in matched_strings:
#     print(matched_string)

# #finally. works great. but not list? Convert to list so that csv doesn't place each letter of string in separate cell


with open('fellowhip_extended_scrape.csv', 'w', newline= '', encoding='utf8') as file:
    writer = csv.writer(file)
    header = ['Speaker']
    writer.writerow(header)

    my_regex = re.compile(r"[A-Za-z]+:{1}")
    lines = my_regex.findall(soup.get_text())
    for line in lines:
        writer.writerow([line]) #line is one large string to my knowledge. Converted to list or problems with csv






