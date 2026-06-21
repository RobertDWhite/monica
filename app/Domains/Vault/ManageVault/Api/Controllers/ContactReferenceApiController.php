<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Http\Controllers\ApiController;
use Illuminate\Http\Request;

/**
 * @group Vault management
 *
 * @subgroup Reference data
 *
 * Lookup lists the mobile client needs to populate pickers when creating or
 * editing contact modules (information types, genders, relationship types,
 * group types, mood parameters, life-event categories, etc.).
 */
class ContactReferenceApiController extends ApiController
{
    public function __construct()
    {
        $this->middleware('abilities:read');

        parent::__construct();
    }

    public function index(Request $request, string $vaultId)
    {
        $account = $request->user()->account;
        $vault = $account->vaults()->findOrFail($vaultId);

        $meContact = $request->user()->getContactInVault($vault);

        return response()->json([
            'data' => [
                'me_contact_id' => optional($meContact)->id,
                'contact_information_types' => $account->contactInformationTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'name' => $type->name,
                        'protocol' => $type->protocol,
                        'type' => $type->type,
                    ]),
                'address_types' => $account->addressTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'name' => $type->name,
                    ]),
                'important_date_types' => $vault->contactImportantDateTypes()
                    ->get()
                    ->map(fn ($type) => [
                        'id' => $type->id,
                        'label' => $type->label,
                    ]),
                'labels' => $vault->labels()
                    ->get()
                    ->map(fn ($l) => [
                        'id' => $l->id,
                        'name' => $l->name,
                        'bg_color' => $l->bg_color,
                        'text_color' => $l->text_color,
                    ]),
                'groups' => $vault->groups()
                    ->get()
                    ->map(fn ($g) => ['id' => $g->id, 'name' => $g->name]),
                'companies' => $vault->companies()
                    ->get()
                    ->map(fn ($c) => ['id' => $c->id, 'name' => $c->name]),
                'genders' => $account->genders()
                    ->get()
                    ->map(fn ($g) => ['id' => $g->id, 'name' => $g->name]),
                'pronouns' => $account->pronouns()
                    ->get()
                    ->map(fn ($p) => ['id' => $p->id, 'name' => $p->name]),
                'religions' => $account->religions()
                    ->get()
                    ->map(fn ($r) => ['id' => $r->id, 'name' => $r->name]),
                'pet_categories' => $account->petCategories()
                    ->get()
                    ->map(fn ($c) => ['id' => $c->id, 'name' => $c->name]),
                'currencies' => $account->currencies()
                    ->wherePivot('active', true)
                    ->get()
                    ->map(fn ($c) => ['id' => $c->id, 'code' => $c->code]),
                'mood_parameters' => $vault->moodTrackingParameters()
                    ->get()
                    ->map(fn ($p) => [
                        'id' => $p->id,
                        'label' => $p->label,
                        'hex_color' => $p->hex_color,
                    ]),
                'quick_fact_templates' => $vault->quickFactsTemplateEntries()
                    ->get()
                    ->map(fn ($t) => ['id' => $t->id, 'label' => $t->label]),
                'relationship_types' => $account->relationshipGroupTypes()
                    ->with('types')
                    ->get()
                    ->flatMap(fn ($group) => $group->types->map(fn ($type) => [
                        'id' => $type->id,
                        'name' => $type->name,
                        'reverse_name' => $type->name_reverse_relationship,
                        'group' => $group->name,
                    ])),
                'group_types' => $account->groupTypes()
                    ->with('groupTypeRoles')
                    ->get()
                    ->map(fn ($gt) => [
                        'id' => $gt->id,
                        'label' => $gt->label,
                        'roles' => $gt->groupTypeRoles->map(fn ($role) => [
                            'id' => $role->id,
                            'label' => $role->label,
                        ]),
                    ]),
                'life_event_categories' => $vault->lifeEventCategories()
                    ->with('lifeEventTypes')
                    ->get()
                    ->map(fn ($cat) => [
                        'id' => $cat->id,
                        'label' => $cat->label,
                        'types' => $cat->lifeEventTypes->map(fn ($type) => [
                            'id' => $type->id,
                            'label' => $type->label,
                        ]),
                    ]),
            ],
        ]);
    }
}
