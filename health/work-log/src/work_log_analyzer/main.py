import os

import pandas as pd
from datetime import datetime


def generate_work_summary(file_path='log.csv'):
    """
    Reads a CSV log file, calculates total work hours per month, and prints
    a summary of the work hours for each month found in the log, including a
    day-by-day breakdown with project details.

    Args:
        file_path (str): The path to the CSV file.
    """
    try:
        # 1. Read the CSV file
        df = pd.read_csv(file_path)
    except FileNotFoundError:
        print(f"Error: The file '{file_path}' was not found.")
        return
    except Exception as e:
        print(f"An error occurred while reading the file: {e}")
        return

    # Column names used in the CSV
    time_col = '15 minute work interval started at'
    project_col = 'Project'

    # Check if the required columns exist
    if time_col not in df.columns:
        print(f"Error: The required column '{time_col}' is missing.")
        return

    # Ensure project column is treated as string and fill missing if necessary
    if project_col not in df.columns:
        df[project_col] = 'Unknown'
    else:
        df[project_col] = df[project_col].fillna('Unknown').astype(str)

    # 2. Convert the time column to datetime objects
    df[time_col] = pd.to_datetime(df[time_col], errors='coerce', utc=True)
    df.dropna(subset=[time_col], inplace=True)

    # Define the interval duration
    INTERVAL_MINUTES = 15
    MINUTES_PER_HOUR = 60

    if df.empty:
        print("No valid work entries found in the log.")
        return

    # 3. Extract grouping keys
    df['YearMonth'] = df[time_col].dt.to_period('M')
    df['Date'] = df[time_col].dt.date

    # 4. Calculate hours per day and project
    # Grouping by Date AND Project
    project_daily = df.groupby(['YearMonth', 'Date', project_col]).size().reset_index(name='Intervals')
    project_daily['Hours'] = (project_daily['Intervals'] * INTERVAL_MINUTES) / MINUTES_PER_HOUR

    # 5. Calculate monthly totals
    monthly_intervals = df.groupby('YearMonth').size().reset_index(name='Intervals')
    monthly_intervals['Hours'] = (monthly_intervals['Intervals'] * INTERVAL_MINUTES) / MINUTES_PER_HOUR

    # 6. Format and print the summary
    print("\n--- Work Hours Summary ---")

    monthly_intervals = monthly_intervals.sort_values('YearMonth')

    for _, row in monthly_intervals.iterrows():
        year_month_period = row['YearMonth']
        total_hours = row['Hours']

        month_name = year_month_period.to_timestamp().strftime('%B')
        year = year_month_period.year

        print(f"\nSummary of {year}-{month_name} Work Hours:")
        print(f"Total Intervals: {int(row['Intervals'])}")
        print(f"Total Hours: {total_hours:.2f}")
        print("-" * 30)

        # Filter and sort daily data for this month
        current_month_projects = project_daily[project_daily['YearMonth'] == year_month_period].sort_values(
            by=['Date', project_col])

        # Group by Date to print day-by-day blocks
        unique_dates = current_month_projects['Date'].unique()

        daily_lines = []
        for d in unique_dates:
            day_data = current_month_projects[current_month_projects['Date'] == d]
            day_num = d.day
            total_day_hours = day_data['Hours'].sum()

            # Format project list: "Project(Hours)"
            proj_breakdown = [f"{r[project_col]}({r['Hours']:.2f})" for _, r in day_data.iterrows()]
            proj_str = ", ".join(proj_breakdown)

            daily_lines.append(f"Day {day_num}: {total_day_hours:.2f} hrs [{proj_str}]")

        print("\n".join(daily_lines))


if __name__ == "__main__":
    generate_work_summary(f'{os.getenv("HOME")}/work/log.csv')