# Generated by Django 3.2.7 on 2021-09-23 13:18

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Conversation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('sender_email', models.TextField(db_index=True, verbose_name='E-Mail')),
                ('immobilie_id', models.IntegerField()),
                ('name', models.TextField()),
                ('phone', models.TextField(blank=True)),
                ('street', models.TextField(blank=True)),
                ('zipcode', models.TextField(blank=True)),
                ('city', models.TextField(blank=True)),
                ('source', models.TextField(blank=True)),
                ('rating', models.CharField(default='', max_length=32)),
                ('is_in_trash', models.BooleanField(default=False)),
                ('is_ignored', models.BooleanField(default=False)),
                ('is_junk', models.BooleanField(default=False)),
                ('notes', models.TextField(blank=True)),
                ('is_read', models.BooleanField(default=False)),
                ('is_replied_to', models.BooleanField(default=False)),
                ('has_been_replied_to', models.BooleanField(default=False)),
                ('has_attachments', models.BooleanField(default=False)),
                ('count_messages', models.IntegerField()),
            ],
            options={
                'unique_together': {('immobilie_id', 'sender_email')},
            },
        ),
        migrations.CreateModel(
            name='Message',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('immobilie_id', models.IntegerField()),
                ('message', models.TextField()),
                ('date_sent', models.DateTimeField(blank=True, null=True)),
                ('conversation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='messagearea.conversation')),
            ],
            options={
                'get_latest_by': 'date_sent',
            },
        ),
        migrations.CreateModel(
            name='IncomingMessage',
            fields=[
                ('message_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='messagearea.message')),
                ('from_email', models.TextField(blank=True)),
                ('is_read', models.BooleanField(default=False)),
                ('is_replied_to', models.BooleanField(default=False)),
            ],
            bases=('messagearea.message',),
        ),
        migrations.CreateModel(
            name='OutgoingMessage',
            fields=[
                ('message_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='messagearea.message')),
                ('to_email', models.TextField(blank=True)),
            ],
            bases=('messagearea.message',),
        ),
    ]