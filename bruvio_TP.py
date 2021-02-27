import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output
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

sport_options = []
for sport in df['WorkoutType'].unique():
    sport_options.append({'label': str(sport), 'value': sport})

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
    ]
    ),
    html.Div([
        dcc.Graph(id='graph'),
        dcc.Dropdown(id='sport-picker', options=sport_options, value='Bike')
    ]
    ),
],



    style={'backgroundColor': colors['background']}
)


@app.callback(Output('graph', 'figure'),
              [Input('sport-picker', 'value')])
def update_figure(selected_sport):
    filtered_df = df[df['WorkoutType'] == selected_sport]
    traces = []
    # for continent_name in filtered_df['continent'].unique():
    #     df_by_continent = filtered_df[filtered_df['continent'] == continent_name]
    traces.append(go.Scatter(
        x=filtered_df['TimeTotalInHours'],
        y=filtered_df['TSS'],
        text='TSS',
        mode='markers',
        opacity=0.7,
        marker={'size': 15},
        name=filtered_df['Title']
    ))

    return {
        'data': traces,
        'layout': go.Layout(
            xaxis={'title': 'TimeTotalInHours'},
            yaxis={'title': 'TSS'},
            hovermode='closest'
        )
    }


if __name__ == '__main__':
    app.run_server()
