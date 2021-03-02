import dash
import dash_auth
import flask
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output
import plotly.graph_objs as go
import numpy as np
import pandas as pd

from aws_s3 import *

import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


USERNAME_PASSWORD_PAIRS = [
    ['JamesBond', '007'], ['LouisArmstrong', 'satchmo']
]
server = flask.Flask(__name__)

app = dash.Dash(__name__, server=server,
                external_stylesheets=[dbc.themes.SLATE])

app.scripts.config.serve_locally = True
app.css.config.serve_locally = True
# auth = dash_auth.BasicAuth(app, USERNAME_PASSWORD_PAIRS)

# app = dash.Dash()

colors = {
    'background': '#111111',
    'text': 'rgb(255,0,0)',
    'plots': 'rgb(255,128,0)'}

bucket = 'bruvio-training-data'
name = 'workouts_bruvio_2020.csv'

# df = read_df_from_s3(name, bucket)
df = pd.read_csv('workouts_bruvio_2020.csv')

sport_options = []
for sport in df['WorkoutType'].unique():
    if sport == 'Day Off':
        continue
    else:
        sport_options.append({'label': str(sport), 'value': sport})

# sport_options.remove('Day Off')

columns = df.columns
remove_list = ['Title', 'WorkoutType', 'WorkoutDescription',
               'WorkoutDay', 'CoachComments', 'AthleteComments']
features = [x for x in columns if x not in remove_list]

bike_power_avg = df[df['WorkoutType'] == 'Bike']['PowerAverage']
bike_TimeTotalInHours = df[df['WorkoutType'] == 'Bike']['TimeTotalInHours']

run_power_avg = df[df['WorkoutType'] == 'Run']['PowerAverage']
run_TimeTotalInHours = df[df['WorkoutType'] == 'Run']['TimeTotalInHours']


app.layout = html.Div(children=[
    html.H1(children='My Training Dashboard.',
            style={
                'textAlign': 'center',
                'color': colors['text']
            }
            ),
    html.Div(children=[
        dcc.Graph(
            id='scatter3',
            figure={
                'data': [
                    go.Scatter(
                        x=bike_TimeTotalInHours,
                        y=bike_power_avg,
                        mode='markers',
                        text=df['Title'],
                        marker={
                            'size': 12,
                            'color': 'rgb(51,204,153)',
                            'symbol': 'pentagon',
                            'line': {'width': 2}
                        }
                    )
                ],
                'layout': go.Layout(
                    plot_bgcolor=colors['background'],
                    paper_bgcolor=colors['background'],
                    font={
                        'color': colors['plots']
                    },
                    title='Bike Data Scatterplot',
                    xaxis={'title': 'TimeTotalInHours'},
                    yaxis={'title': 'PowerAverage'},
                    hovermode='closest'
                )
            }
        ),
        dcc.Graph(
            id='scatter4',
            figure={
                'data': [
                    go.Scatter(
                        x=run_TimeTotalInHours,
                        y=run_power_avg,
                        mode='markers',
                        text=df['Title'],
                        marker={
                            'size': 12,
                            'color': 'rgb(51,204,153)',
                            'symbol': 'pentagon',
                            'line': {'width': 2}
                        }
                    )
                ],
                'layout': go.Layout(
                    plot_bgcolor=colors['background'],
                    paper_bgcolor=colors['background'],
                    font={
                        'color': colors['plots']
                    },
                    title='Run Data Scatterplot',
                    xaxis={'title': 'TimeTotalInHours'},
                    yaxis={'title': 'PowerAverage'},
                    hovermode='closest'
                )
            }
        ),
    ]
    ),
    html.Div([

        dcc.Dropdown(id='sport-picker', options=sport_options, value='Bike'),
        dcc.Graph(id='graph'),
    ]
    ),

    html.Div([

        html.Div([
            dcc.Dropdown(
                id='xaxis',
                options=[{'label': i.title(), 'value': i} for i in features],
                value='TimeTotalInHours'
            )
        ],
            style={'width': '48%', 'display': 'inline-block'}),

        html.Div([
            dcc.Dropdown(
                id='yaxis',
                options=[{'label': i.title(), 'value': i} for i in features],
                value='PowerAverage'
            )
        ], style={'width': '48%', 'float': 'right', 'display': 'inline-block'}),

        dcc.Graph(id='feature-graphic')
    ], style={'padding': 10})


],


    style={'backgroundColor': colors['background']}
)


@ app.callback(Output('graph', 'figure'),
               [Input('sport-picker', 'value')])
def update_figure(selected_sport):
    filtered_df = df[df['WorkoutType'] == selected_sport]
    traces = []
    # for continent_name in filtered_df['continent'].unique():
    #     df_by_continent = filtered_df[filtered_df['continent'] == continent_name]
    # print(filtered_df['Title'])
    traces.append(go.Scatter(
        x=filtered_df['TimeTotalInHours'],
        y=filtered_df['TSS'],
        text=filtered_df['Title'],
        mode='markers',
        opacity=0.7,
        marker={'size': 15},
        # ,
        # name=filtered_df['Title']
        # name='ciao'
    ))

    return {
        'data': traces,
        'layout': go.Layout(

            plot_bgcolor=colors['background'],
            paper_bgcolor=colors['background'],
            font={
                'color': colors['plots']
            },


            xaxis={'title': 'TimeTotalInHours'},
            yaxis={'title': 'TSS'},
            hovermode='closest'
        )
    }


@ app.callback(
    Output('feature-graphic', 'figure'),
    [Input('xaxis', 'value'),
     Input('yaxis', 'value'),
     Input('sport-picker', 'value')])
def update_graph(xaxis_name, yaxis_name, selected_sport):
    filtered_df = df[df['WorkoutType'] == selected_sport]
    return {
        'data': [go.Scatter(
            x=filtered_df[xaxis_name],
            y=filtered_df[yaxis_name],
            text=df['Title'],
            mode='markers',
            marker={
                'size': 15,
                'opacity': 0.5,
                'line': {'width': 0.5, 'color': 'white'}
            }
        )],
        'layout': go.Layout(

            plot_bgcolor=colors['background'],
            paper_bgcolor=colors['background'],
            font={
                'color': colors['plots']
            },


            xaxis={'title': xaxis_name.title()},
            yaxis={'title': yaxis_name.title()},
            margin={'l': 40, 'b': 40, 't': 10, 'r': 0},
            hovermode='closest'
        )
    }


if __name__ == '__main__':
    app.run_server(debug=True)
