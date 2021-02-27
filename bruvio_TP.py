import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.graph_objs as go
import numpy as np
import pandas as pd
app = dash.Dash()

colors = {
    'background': '#111111',
    'text': '#7FDBFF',
    'plots': '9EA0A1'}

df = pd.read_csv(
    '/Users/bruvio/Documents/Dropbox/Documenti/SpOrT/Triathlon/Training/bruvio_tri/workouts_bruvio_2020.csv')


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

    dcc.Graph(
        id='scatter3',
        figure={
            'data': [
                go.Scatter(
                    x=bike_TimeTotalInHours,
                    y=bike_power_avg,
                    mode='markers',
                    marker={
                        'size': 12,
                        'color': 'rgb(51,204,153)',
                        'symbol': 'pentagon',
                        'line': {'width': 2}
                    }
                )
            ],
            'layout': go.Layout(
                # plot_bgcolor=colors['background'],
                # paper_bgcolor=colors['background'],
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
                    marker={
                        'size': 12,
                        'color': 'rgb(51,204,153)',
                        'symbol': 'pentagon',
                        'line': {'width': 2}
                    }
                )
            ],
            'layout': go.Layout(
                # plot_bgcolor=colors['background'],
                # paper_bgcolor=colors['background'],
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

],
    style={'backgroundColor': colors['background']}
)

if __name__ == '__main__':
    app.run_server()
