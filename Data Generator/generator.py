from mimesis.locales import Locale
from mimesis import Generic, Person, Text, Numeric
from mimesis.schema import Field, Schema
from mimesis.data import SAFE_COLORS
from mimesis.enums import Gender
import json


def randomize(data_type: str):
    get_field = Field(locale=Locale.EN)
    get_generic = Generic(locale=Locale.EN)
    get_person = Person(Locale.EN)
    get_text = Text(Locale.EN)
    get_number = Numeric()
    xf = get_field("text.word")
    option_list = {
        "name": f"'{get_person.full_name()}'",
        "long_txt": f"'{get_generic.text.text(1).replace(chr(39), '').replace(chr(44), '').replace(chr(34), '')}'",
        "bool": f"{get_generic.development.boolean()}",
        "short_txt": f"'{xf}'",
        "color": f"'{get_text.color()}'",
        "title": f"'{get_text.title()}'",
        "int": f"{get_number.integer_number(start=0, end=1000)}",
    }
    return option_list[data_type]
    # ["name","long_txt","bool","short_txt","color","title","int"]


def generate_csv(tables: list):
    for table in tables:
        get_value = Field(locale=Locale.EN)
        table_name = table['name']
        n_rows = int(table['rows'])
        fields = table['fields']

        list_of_fields = {}
        for field in fields:
            list_of_fields[field] = "text.word"

        schema = Schema(schema=lambda: {x: get_value(f'{list_of_fields[x]}') for x in list_of_fields})

        # Since v5.6.0 you can do the same thing using multiplication:
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
            list_of_fields[field] = fields[field]
            if list_of_fields[field] not in ["name", "long_txt", "bool", "short_txt", "color", "title", "int"]:
                list_of_fields[field] = "short_txt"

        schema = Schema(schema=lambda: {x: randomize(f'{list_of_fields[x]}') for x in list_of_fields})

        with open(f"finalSQL.sql", 'at') as file:
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
