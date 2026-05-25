<?php

namespace App\Http\Resources;

use App\Domains\Contact\ManageRelationships\Web\ViewHelpers\ModuleFamilySummaryViewHelper;
use App\Domains\Contact\ManageRelationships\Web\ViewHelpers\ModuleRelationshipViewHelper;
use App\Helpers\DateHelper;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Contact
 */
class ContactResource extends JsonResource
{
    /**
     * The relations to eager load so a ContactResource renders every module.
     *
     * Shared by the contact `show` endpoint and every contact-module write
     * endpoint, which all return the fully hydrated contact after a change.
     */
    public static function eagerLoadRelations(): array
    {
        return [
            'file',
            'gender',
            'pronoun',
            'religion',
            'company',
            'contactInformations.contactInformationType',
            'importantDates',
            'addresses',
            'notes.emotion',
            'labels',
            'groups.groupType',
            'relationships',
            'tasks',
            'calls.callReason',
            'calls.emotion',
            'pets.petCategory',
            'goals.streaks',
            'quickFacts.vaultQuickFactsTemplate',
            'timelineEvents.lifeEvents.lifeEventType',
            'timelineEvents.lifeEvents.emotion',
            'timelineEvents.lifeEvents.currency',
            'loansAsLoaner.currency',
            'loansAsLoanee.currency',
            'moodTrackingEvents.moodTrackingParameter',
            'lifeMetrics',
            'reminders',
            'posts',
        ];
    }

    /**
     * Partner(s) and children of the contact, in a flat client-friendly shape.
     * Mirrors the web family summary so app + site stay consistent.
     */
    /**
     * All relationships in both directions, flattened with the correct
     * directional label + group, so reverse relationships (parent of a child,
     * etc.) appear automatically without being added on both contacts.
     */
    private function relationshipsList($request): array
    {
        $data = ModuleRelationshipViewHelper::data($this->resource, $request->user());

        return collect($data['relationship_group_types'])
            ->flatMap(fn ($group) => collect($group['relationship_types'])->map(fn ($r) => [
                'contact_id' => $r['contact']['id'],
                'name' => $r['contact']['name'],
                'avatar' => $r['contact']['avatar'],
                'relationship_type' => $r['relationship_type']['name'],
                'group' => $group['name'],
            ]))
            ->values()
            ->all();
    }

    private function familySummary($request): array
    {
        $summary = ModuleFamilySummaryViewHelper::data($this->resource, $request->user());

        $map = fn ($rows) => collect($rows)->map(fn ($r) => [
            'contact_id' => $r['contact']['id'],
            'name' => $r['contact']['name'],
            'avatar' => $r['contact']['avatar'],
            'age' => $r['contact']['age'],
        ])->values();

        return [
            'partners' => $map($summary['love_relationships']),
            'children' => $map($summary['family_relationships']),
        ];
    }

    public function toArray($request): array
    {
        return [
            // Core identity
            'id' => $this->id,
            'vault_id' => $this->vault_id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'middle_name' => $this->middle_name,
            'nickname' => $this->nickname,
            'maiden_name' => $this->maiden_name,
            'prefix' => $this->prefix,
            'suffix' => $this->suffix,
            'listed' => $this->listed,
            'can_be_deleted' => $this->can_be_deleted,
            'avatar' => $this->avatar,

            // Simple BelongsTo fields (no extra query when eager loaded)
            'gender' => $this->gender?->name,
            'pronoun' => $this->pronoun?->name,
            'religion' => $this->religion?->name,
            'job_position' => $this->job_position,
            'company' => $this->company ? [
                'id' => $this->company->id,
                'name' => $this->company->name,
            ] : null,

            // Contact info
            'contact_informations' => $this->when(
                $this->relationLoaded('contactInformations'),
                fn () => $this->contactInformations->map(fn ($info) => [
                    'id' => $info->id,
                    'type_id' => $info->contactInformationType->id,
                    'label' => $info->contactInformationType->name,
                    'type' => $info->contactInformationType->type,
                    'protocol' => $info->contactInformationType->protocol,
                    'data' => $info->data,
                ])
            ),

            // Important dates
            'important_dates' => $this->when(
                $this->relationLoaded('importantDates'),
                fn () => $this->importantDates->map(fn ($date) => [
                    'id' => $date->id,
                    'label' => $date->label,
                    'day' => $date->day,
                    'month' => $date->month,
                    'year' => $date->year,
                ])
            ),

            // Addresses
            'addresses' => $this->when(
                $this->relationLoaded('addresses'),
                fn () => $this->addresses->map(fn ($addr) => [
                    'id' => $addr->id,
                    'line_1' => $addr->line_1,
                    'line_2' => $addr->line_2,
                    'city' => $addr->city,
                    'province' => $addr->province,
                    'postal_code' => $addr->postal_code,
                    'country' => $addr->country,
                    'is_past_address' => (bool) $addr->pivot?->is_past_address,
                ])
            ),

            // Notes
            'notes' => $this->when(
                $this->relationLoaded('notes'),
                fn () => $this->notes->map(fn ($note) => [
                    'id' => $note->id,
                    'title' => $note->title,
                    'body' => $note->body,
                    'emotion' => $note->emotion?->name,
                    'created_at' => DateHelper::getTimestamp($note->created_at),
                    'updated_at' => DateHelper::getTimestamp($note->updated_at),
                ])
            ),

            // Labels
            'labels' => $this->when(
                $this->relationLoaded('labels'),
                fn () => $this->labels->map(fn ($label) => [
                    'id' => $label->id,
                    'name' => $label->name,
                    'bg_color' => $label->bg_color,
                    'text_color' => $label->text_color,
                ])
            ),

            // Groups
            'groups' => $this->when(
                $this->relationLoaded('groups'),
                fn () => $this->groups->map(fn ($group) => [
                    'id' => $group->id,
                    'name' => $group->name,
                    'type' => $group->groupType?->label,
                ])
            ),

            // Relationships (linked contacts)
            // Bidirectional, directional relationships (e.g. a contact listed
            // as someone's daughter shows that person as her parent), each with
            // its relationship label and group (Family / Love / …).
            'relationships' => $this->relationshipsList($request),

            // Family associations — partner(s) + children — always present so
            // clients can surface them on every contact.
            'family' => $this->familySummary($request),

            // Tasks
            'tasks' => $this->when(
                $this->relationLoaded('tasks'),
                fn () => $this->tasks->map(fn ($task) => [
                    'id' => $task->id,
                    'label' => $task->label,
                    'description' => $task->description,
                    'completed' => $task->completed,
                    'due_at' => $task->due_at ? DateHelper::getTimestamp($task->due_at) : null,
                ])
            ),

            // Calls
            'calls' => $this->when(
                $this->relationLoaded('calls'),
                fn () => $this->calls->map(fn ($call) => [
                    'id' => $call->id,
                    'reason' => $call->callReason?->label,
                    'description' => $call->description,
                    'called_at' => $call->called_at ? DateHelper::getTimestamp($call->called_at) : null,
                    'duration' => $call->duration,
                    'type' => $call->type,
                    'answered' => $call->answered,
                    'who_initiated' => $call->who_initiated,
                    'emotion' => $call->emotion?->name,
                ])
            ),

            // Pets
            'pets' => $this->when(
                $this->relationLoaded('pets'),
                fn () => $this->pets->map(fn ($pet) => [
                    'id' => $pet->id,
                    'name' => $pet->name,
                    'category' => $pet->petCategory?->name,
                ])
            ),

            // Goals
            'goals' => $this->when(
                $this->relationLoaded('goals'),
                fn () => $this->goals->map(fn ($goal) => [
                    'id' => $goal->id,
                    'name' => $goal->name,
                    'active' => $goal->active,
                    'streak_count' => $goal->relationLoaded('streaks') ? $goal->streaks->count() : null,
                ])
            ),

            // Quick facts
            'quick_facts' => $this->when(
                $this->relationLoaded('quickFacts'),
                fn () => $this->quickFacts->map(fn ($qf) => [
                    'id' => $qf->id,
                    'label' => $qf->vaultQuickFactsTemplate?->label,
                    'content' => $qf->content,
                ])
            ),

            // Timeline events
            'timeline_events' => $this->when(
                $this->relationLoaded('timelineEvents'),
                fn () => $this->timelineEvents->map(fn ($te) => [
                    'id' => $te->id,
                    'label' => $te->label,
                    'started_at' => $te->started_at ? DateHelper::getTimestamp($te->started_at) : null,
                    'life_events' => $te->relationLoaded('lifeEvents')
                        ? $te->lifeEvents->map(fn ($le) => [
                            'id' => $le->id,
                            'type' => $le->lifeEventType?->label,
                            'summary' => $le->summary,
                            'description' => $le->description,
                            'happened_at' => $le->happened_at ? DateHelper::getTimestamp($le->happened_at) : null,
                            'emotion' => $le->emotion?->name,
                            'costs' => $le->costs,
                            'currency' => $le->currency?->code,
                        ])
                        : [],
                ])
            ),

            // Loans
            'loans' => $this->when(
                $this->relationLoaded('loansAsLoaner') && $this->relationLoaded('loansAsLoanee'),
                function () {
                    $lent = $this->loansAsLoaner->map(fn ($loan) => [
                        'id' => $loan->id,
                        'direction' => 'lent',
                        'name' => $loan->name,
                        'description' => $loan->description,
                        'amount' => $loan->amount_lent,
                        'currency' => $loan->currency?->code,
                        'loaned_at' => $loan->loaned_at ? DateHelper::getTimestamp($loan->loaned_at) : null,
                        'settled' => $loan->settled,
                        'settled_at' => $loan->settled_at ? DateHelper::getTimestamp($loan->settled_at) : null,
                    ]);
                    $borrowed = $this->loansAsLoanee->map(fn ($loan) => [
                        'id' => $loan->id,
                        'direction' => 'borrowed',
                        'name' => $loan->name,
                        'description' => $loan->description,
                        'amount' => $loan->amount_lent,
                        'currency' => $loan->currency?->code,
                        'loaned_at' => $loan->loaned_at ? DateHelper::getTimestamp($loan->loaned_at) : null,
                        'settled' => $loan->settled,
                        'settled_at' => $loan->settled_at ? DateHelper::getTimestamp($loan->settled_at) : null,
                    ]);
                    return $lent->merge($borrowed)->values();
                }
            ),

            // Reminders
            'reminders' => $this->when(
                $this->relationLoaded('reminders'),
                fn () => $this->reminders->map(fn ($r) => [
                    'id' => $r->id,
                    'label' => $r->label,
                    'day' => $r->day,
                    'month' => $r->month,
                    'year' => $r->year,
                    'type' => $r->type,
                    'frequency_number' => $r->frequency_number,
                ])
            ),

            // Mood tracking
            'mood_tracking_events' => $this->when(
                $this->relationLoaded('moodTrackingEvents'),
                fn () => $this->moodTrackingEvents->map(fn ($m) => [
                    'id' => $m->id,
                    'label' => $m->moodTrackingParameter?->label,
                    'hex_color' => $m->moodTrackingParameter?->hex_color,
                    'note' => $m->note,
                    'hours_slept' => $m->number_of_hours_slept,
                    'rated_at' => $m->rated_at ? DateHelper::getTimestamp($m->rated_at) : null,
                ])
            ),

            // Life metrics
            'life_metrics' => $this->when(
                $this->relationLoaded('lifeMetrics'),
                fn () => $this->lifeMetrics->map(fn ($lm) => [
                    'id' => $lm->id,
                    'label' => $lm->label,
                ])
            ),

            // Documents / files (non-avatar)
            'documents' => $this->when(
                $this->relationLoaded('files'),
                fn () => $this->files->map(fn ($f) => [
                    'id' => $f->id,
                    'name' => $f->name,
                    'mime_type' => $f->mime_type,
                    'type' => $f->type,
                    'size' => $f->size,
                    'url' => $f->cdn_url ?? $f->original_url,
                ])
            ),

            // Posts (journal entries)
            'posts' => $this->when(
                $this->relationLoaded('posts'),
                fn () => $this->posts->map(fn ($post) => [
                    'id' => $post->id,
                    'title' => $post->title,
                    'excerpt' => $post->excerpt,
                    'written_at' => $post->written_at ? DateHelper::getTimestamp($post->written_at) : null,
                ])
            ),

            'created_at' => DateHelper::getTimestamp($this->created_at),
            'updated_at' => DateHelper::getTimestamp($this->updated_at),
            'links' => [
                'self' => route('api.vaults.contacts.show', [$this->vault_id, $this->id]),
            ],
        ];
    }
}
