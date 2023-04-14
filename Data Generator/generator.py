from mimesis.locales import Locale
from mimesis import Generic, Person, Text, Numeric, Datetime
from mimesis.schema import Field, Schema
from mimesis.data import SAFE_COLORS
from mimesis.enums import Gender
from mimesis.random import get_random_item
from enum import Enum
import json

valid_data_types = ["name", "description", "bool", "short_txt", "color", "title", "int", "chicken_gender", "date"]


class Chiken_Gender(Enum):
    Hen = 1
    Rooster = 2


def randomize(data_type: str):
    get_generic = Generic(locale=Locale.EN)
    get_text = Text(Locale.EN)
    get_number = Numeric()

    if data_type == "name":
        get_person = Person(Locale.EN)
        return f"'{get_person.full_name()[:50].replace(chr(39), '').replace(chr(44), '').replace(chr(59), '')}'"
    elif data_type == "description":
        return f"'{get_generic.text.text(1)[:100].replace(chr(39), '').replace(chr(44), '').replace(chr(59), '')}'"
    elif data_type == "bool":
        return f"{get_generic.development.boolean()}"
    elif data_type == "short_txt":
        get_field = Field(locale=Locale.EN)
        xf = get_field("text.word")[:50].replace(chr(39), '').replace(chr(44), '').replace(chr(59), '')
        return f"'{xf}'"
    elif data_type == "color":
        return f"'{get_text.color()}'"
    elif data_type == "title":
        return f"'{get_text.title()[:50].replace(chr(39), '').replace(chr(44), '').replace(chr(59), '')}'"
    elif data_type == "int":
        return f"{get_number.integer_number(start=0, end=1000)}"
    elif data_type == "chicken_gender":
        return f"'{get_random_item(Chiken_Gender).name}'"
    elif data_type == "date":
        get_date = Datetime()
        return f"'{get_date.date()}'"


def generate_csv(tables: list):
    for table in tables:
        get_value = Field(locale=Locale.EN)
        table_name = table['name']
        n_rows = int(table['rows'])
        fields = table['fields']

        list_of_fields = {}
        for field in fields:
            if fields[field] in valid_data_types:
                list_of_fields[field] = fields[field]
            else:
                list_of_fields[field] = "short_txt"

        schema = Schema(schema=lambda: {x: get_value(f'{list_of_fields[x]}') for x in list_of_fields})

        schema.to_csv(file_path=f'_{table_name}.csv', iterations=n_rows)


def generate_sql_insert(tables: list):
    for table in tables:
        get_value = Field(locale=Locale.EN)
        table_name = table['name']
        n_rows = int(table['rows'])
        fields = table['fields']
        field_list = ''.join(f'{x}, ' for x in fields)[:-2]
        # print(f'insert into {table_name} ({field_list}) values(')

        list_of_fields = {}
        for field in fields:
            if fields[field] in valid_data_types:
                list_of_fields[field] = fields[field]
            else:
                list_of_fields[field] = "short_txt"

        schema = Schema(schema=lambda: {x: randomize(f'{list_of_fields[x]}') for x in list_of_fields})

        with open(f"sql_insert_data.sql", 'at') as file:
            for obj in schema.iterator(n_rows):
                obs = ''.join(f'{obj[x]}, ' for x in obj)[:-2]
                # print(f'insert into {table_name} ({field_list}) values( {obs} );')
                file.write(f'insert into {table_name} ({field_list}) values( {obs} ); \n')


def main():
    with open('config.json') as table_file:
        config = json.load(table_file)

    file_type = config["output_type"]
    tables = config["tables"]

    if file_type == "sql":
        generate_sql_insert(tables)
    elif file_type == "csv":
        generate_csv(tables)
    else:
        print(f"Filetype {file_type} not supported, only sql and csv")


main()
